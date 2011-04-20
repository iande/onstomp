# -*- encoding: utf-8 -*-

# Common behavior for all connections.
class OnStomp::Connections::Base
  include OnStomp::Interfaces::ConnectionEvents
  attr_reader :version, :socket, :client
  attr_reader :last_transmitted_at, :last_received_at
  
  # The approximate maximum number of bytes to write per call to
  # {#io_process_write}.
  MAX_BYTES_PER_WRITE = 1024 * 8
  # The maximum number of bytes to read per call to {#io_process_read}
  MAX_BYTES_PER_READ = 1024 * 4
  
  # Creates a new connection using the given {#socket} object and
  # {OnStomp::Client client}. The {#socket} object will generally be a `TCPSocket`
  # or an `OpenSSL::SSL::SSLSocket` and must support the methods `read_nonblock`
  # `write_nonblock`, and `close`.
  # @param [TCPSocket,OpenSSL::SSL::SSLSocket] socket
  # @param [OnStomp::Client] client
  def initialize socket, client
    @socket = socket
    @write_mutex = Mutex.new
    @closing = false
    @write_buffer = []
    @read_buffer = []
    @client = client
    @connection_up = false
  end
  
  # Performs any necessary configuration of the connection from the CONNECTED
  # frame sent by the broker and a `Hash` of pending callbacks. This method
  # is called after the protocol negotiation has taken place between client
  # and broker, and the connection that receives it will be the connection
  # used by the client for the duration of the session.
  # @param [OnStomp::Components::Frame] connected
  # @param [{Symbol => Proc}] con_cbs
  def configure connected, con_cbs
    @version = connected.header?(:version) ? connected[:version] : '1.0'
    install_bindings_from_client con_cbs
  end
  
  # Returns true if the socket has not been closed, false otherwise.
  # @return [true,false]
  def connected?
    !socket.closed?
  end
  
  # Closes the {#socket}. If `blocking` is true, the socket will be closed
  # immediately, otherwies the socket will remain open until {#io_process_write}
  # has finished writing all of its buffered data. Once this method has been
  # invoked, {#write_frame_nonblock} will not enqueue any additional frames
  # for writing.
  # @param [true,false] blocking
  def close blocking=false
    @write_mutex.synchronize { @closing = true }
    if blocking
      io_process_write until @write_buffer.empty?
      socket.close
    end
  end
  
  # Exchanges the CONNECT/CONNECTED frame handshake with the broker and returns
  # the version detected along with the received CONNECTED frame. The supplied
  # list of headers will be merged into the CONNECT frame sent to the broker.
  # @param [OnStomp::Client] client
  # @param [Array<Hash>] headers
  def connect client, *headers
    write_frame_nonblock connect_frame(*headers)
    client_con = nil
    until client_con
      io_process_write { |f| client_con ||= f }
    end
    broker_con = nil
    until broker_con
      io_process_read { |f| broker_con ||= f }
    end
    raise OnStomp::ConnectFailedError if broker_con.command != 'CONNECTED'
    vers = broker_con.header?(:version) ? broker_con[:version] : '1.0'
    raise OnStomp::UnsupportedProtocolVersionError, vers unless client.versions.include?(vers)
    @connection_up = true
    [ vers, broker_con ]
  end
  
  # Checks if the missing method ends with '_frame', and if so raises a
  # {OnStomp::UnsupportedCommandError} exception.
  # @raise [OnStomp::UnsupportedCommandError]
  def method_missing meth, *args, &block
    if meth.to_s =~ /^(.*)_frame$/
      raise OnStomp::UnsupportedCommandError, $1.upcase
    else
      super
    end
  end
  
  # Flushes the write buffer by invoking {#io_process_write} until the
  # buffer is empty.
  def flush_write_buffer
    io_process_write until @write_buffer.empty?
  end
  
  # Makes a single call to {#io_process_write} and a single call to
  # {#io_process_read}
  def io_process &cb
    io_process_write &cb
    io_process_read &cb
    if @connection_up && !connected?
      triggered_close 'connection timed out', :died
    end
  end
  
  # Serializes the given frame and adds the data to the connections internal
  # write buffer
  # @param [OnStomp::Components::Frame] frame
  def write_frame_nonblock frame
    ser = serializer.frame_to_bytes frame
    push_write_buffer ser, frame
  end
  
  # Adds data and frame pair to the end of the write buffer
  # @param [String] data
  # @param [OnStomp::Components::Frame]
  def push_write_buffer data, frame
    @write_mutex.synchronize {
      @write_buffer << [data, frame] unless @closing
    }
  end
  # Removes the first data and frame pair from the write buffer
  # @param [String] data
  # @param [OnStomp::Components::Frame]
  def shift_write_buffer
    @write_mutex.synchronize { @write_buffer.shift }
  end
  # Adds the remains of data and frame pair to the head of the write buffer
  # @param [String] data
  # @param [OnStomp::Components::Frame]
  def unshift_write_buffer data, frame
    @write_mutex.synchronize { @write_buffer.unshift [data, frame] }
  end
  
  # Writes serialized frame data to the socket if the write buffer is not
  # empty and socket is ready for writing. Once a complete frame has
  # been written, this method will call {OnStomp::Client#dispatch_transmitted}
  # to notify the client that the frame has been sent to the broker. If a
  # complete frame cannot be written without blocking, the unsent data is
  # sent to the head of the write buffer to be processed first the next time
  # this method is invoked.
  def io_process_write
    begin
      if @write_buffer.length > 0 && IO.select(nil, [socket], nil, 0.1)
        to_shift = @write_buffer.length / 3
        written = 0
        while written < MAX_BYTES_PER_WRITE
          data, frame = shift_write_buffer
          break unless data && connected?
          begin
            w = socket.write_nonblock(data)
          rescue Errno::EINTR, Errno::EAGAIN, Errno::EWOULDBLOCK
            # writing will either block, or cannot otherwise be completed,
            # put data back and try again some other day
            unshift_write_buffer data, frame
            break
          end
          written += w
          @last_transmitted_at = Time.now
          if w < data.length
            unshift_write_buffer data[w..-1], frame
          else
            yield frame if block_given?
            client.dispatch_transmitted frame
          end
        end
      end
    rescue Exception
      triggered_close $!.message, :terminated
      raise
    end
    if @write_buffer.empty? && @closing
      triggered_close 'client disconnected'
    end
  end
  
  # Reads serialized frame data from the socket if we're connected and
  # and the socket is ready for reading.  The received data will be pushed
  # to the end of a read buffer, which is then sent to the connection's
  # {OnStomp::Connections::Serializers serializer} for processing.
  def io_process_read
    begin
      if connected? && IO.select([socket], nil, nil, 0.1)
        if data = socket.read_nonblock(MAX_BYTES_PER_READ)
          @read_buffer << data
          @last_received_at = Time.now
          serializer.bytes_to_frame(@read_buffer) do |frame|
            yield frame if block_given?
            client.dispatch_received frame
          end
        else
          triggered_close $!.message, :terminated
        end
      end
    rescue Errno::EINTR, Errno::EAGAIN, Errno::EWOULDBLOCK
      # do not
    rescue EOFError
      triggered_close $!.message
    rescue Exception
      triggered_close $!.message, :terminated
      raise
    end
  end
  
  private
  def triggered_close msg, *evs
    @connection_up = false
    @closing = false
    socket.close rescue nil
    evs.each { |ev| trigger_connection_event ev, msg }
    trigger_connection_event :closed, msg
    @write_buffer.clear
  end
end
