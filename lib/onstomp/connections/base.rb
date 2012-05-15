# -*- encoding: utf-8 -*-

# Common behavior for all connections.
class OnStomp::Connections::Base
  include OnStomp::Interfaces::ConnectionEvents
  attr_reader :version, :socket, :client
  attr_reader :last_transmitted_at, :last_received_at
  attr_reader :write_timeout, :read_timeout
  
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
    self.read_timeout = 120
    self.write_timeout = nil
    setup_non_blocking_methods
  end

  # Sets the read timeout when connecting to the specified number of seconds.
  # If set to nil, no read timeout checking will be performed.
  # @param [Number] secs
  def read_timeout= secs
    if secs
      @read_timeout = secs
      @read_timeout_ms = secs * 1000
    else
      @read_timeout = @read_timeout_ms = nil
    end
  end

  # Sets the maximum number of seconds to wait between IO writes before
  # declaring the connection blocked. This timeout is ignored if there is no
  # data waiting to be written. If set to `nil`, connection write timeout
  # checking will be performed.
  # @param [Number, nil] secs
  def write_timeout= secs
    if secs
      @write_timeout = secs
      @write_timeout_ms = secs * 1000
    else
      @write_timeout = @write_timeout_ms = nil
    end
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
    # I really don't care for this. A core part of the CONNECT/CONNECTED
    # exchange can only be accomplished through subclasses.
    write_frame_nonblock connect_frame(*headers)
    client_con = nil
    until client_con
      io_process_write { |f| client_con ||= f }
    end
    update_last_received
    broker_con = nil
    until broker_con
      io_process_read(true) { |f| broker_con ||= f }
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
  
  # Number of milliseconds since data was last transmitted to the broker or
  # `nil` if no data has been transmitted when the method is called.
  # @return [Fixnum, nil]
  def duration_since_transmitted
    last_transmitted_at && ((Time.now.to_f - last_transmitted_at) * 1000)
  end
  
  # Number of milliseconds since data was last received from the broker or
  # `nil` if no data has been received when the method is called.
  # @return [Fixnum, nil]
  def duration_since_received
    last_received_at && ((Time.now.to_f - last_received_at) * 1000)
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
      update_last_write_activity if @write_buffer.empty?
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
    if ready_for_write?
      to_shift = @write_buffer.length / 3
      written = 0
      while written < MAX_BYTES_PER_WRITE
        data, frame = shift_write_buffer
        break unless data && connected?
        begin
          w = write_nonblock data
        rescue Errno::EINTR, Errno::EAGAIN, Errno::EWOULDBLOCK
          # writing will either block, or cannot otherwise be completed,
          # put data back and try again some other day
          unshift_write_buffer data, frame
          break
        rescue Exception
          triggered_close $!.message, :terminated
          raise
        end
        written += w
        update_last_write_activity
        update_last_transmitted
        if w < data.length
          unshift_write_buffer data[w..-1], frame
        else
          yield frame if block_given?
          client.dispatch_transmitted frame
        end
      end
    elsif write_timeout_exceeded?
      triggered_close 'write blocked', :blocked
    end
    if @write_buffer.empty? && @closing
      triggered_close 'client disconnected'
    end
  end
  
  # Reads serialized frame data from the socket if we're connected and
  # and the socket is ready for reading.  The received data will be pushed
  # to the end of a read buffer, which is then sent to the connection's
  # {OnStomp::Connections::Serializers serializer} for processing.
  def io_process_read(connecting=false)
    if ready_for_read?
      begin
        if data = read_nonblock
          @read_buffer << data
          update_last_received
          serializer.bytes_to_frame(@read_buffer) do |frame|
            yield frame if block_given?
            client.dispatch_received frame
          end
        end
      rescue Errno::EINTR, Errno::EAGAIN, Errno::EWOULDBLOCK
        # do not
      rescue EOFError
        triggered_close $!.message
        raise if connecting
      rescue Exception
        # TODO: Fix this potential race condition the right way.
        # This is the problematic area!  If the user (or failover library)
        # try to reconnect the Client when the connection is closed, the
        # exception won't be raised until the IO Processing thread has
        # already been joined to the main thread.  Thus, the connection gets
        # re-established, the "dying" thread re-enters here, and immediately
        # raises the exception that terminated it.
        triggered_close $!.message, :terminated
        raise
      end
    end
    if connecting && read_timeout_exceeded?
      triggered_close 'read blocked', :blocked
      raise OnStomp::ConnectionTimeoutError
    end
  end
  
  private
  def update_last_received
    @last_received_at = Time.now.to_f
  end

  def update_last_write_activity
    @last_write_activity = Time.now.to_f
  end

  def update_last_transmitted
    @last_transmitted_at = Time.now.to_f
  end

  def duration_since_write_activity
    (Time.now.to_f - @last_write_activity) * 1000
  end
  
  # Returns true if the connection has buffered data to write and the
  # socket is ready to be written to. If checking the socket's state raises
  # an exception, the connection will be closed (triggering an
  # `on_terminated` event) and the error will be re-raised.
  def ready_for_write?
    begin
      @write_buffer.length > 0 && IO.select(nil, [socket], nil, 0.1)
    rescue Exception
      triggered_close $!.message, :terminated
      raise
    end
  end
  
  # Returns true if the connection has buffered data to write and the
  # socket is ready to be written to. If checking the socket's state raises
  # an exception, the connection will be closed (triggering an
  # `on_terminated` event) and the error will be re-raised.
  def ready_for_read?
    begin
      connected? && IO.select([socket], nil, nil, 0.1)
    rescue Exception
      triggered_close $!.message, :terminated
      raise
    end
  end
  
  # Returns true if a `write_timeout` has been set, the connection has buffered
  # data to write, and `duration_since_transmitted` is greater than
  # `write_timeout`
  def write_timeout_exceeded?
    @write_timeout_ms && @write_buffer.length > 0 &&
      duration_since_write_activity > @write_timeout_ms
  end
  
  # Returns true if a `read_timeout` has been set and
  # `duration_since_received` is greater than `read_timeout`
  # This is only used when establishing the connection through the CONNECT/
  # CONNECTED handshake.  After that, it is up to heart-beating.
  def read_timeout_exceeded?
    @read_timeout_ms && duration_since_received > @read_timeout_ms
  end
  
  def triggered_close msg, *evs
    @connection_up = false
    @closing = false
    socket.close rescue nil
    evs.each { |ev| trigger_connection_event ev, msg }
    trigger_connection_event :closed, msg
    @write_buffer.clear
  end
  
  # OpenSSL sockets in Ruby 1.8.7 and JRuby (as of jruby-openssl 0.7.3)
  # do NOT support non-blocking IO natively. Such a hack, and such a huge
  # oversight on my part. We define some methods on this instance to use
  # the right read/write operations. Fortunately, this gets done at
  # initialization and only has to happen once.
  def setup_non_blocking_methods
    read_mod = @socket.respond_to?(:read_nonblock) ? NonblockingRead :
      BlockingRead
    write_mod = @socket.respond_to?(:write_nonblock) ? NonblockingWrite :
      BlockingWrite
    self.extend read_mod
    self.extend write_mod
  end

  module NonblockingRead
    def read_nonblock
      socket.read_nonblock MAX_BYTES_PER_READ
    end
  end
  module NonblockingWrite
    def write_nonblock data
      socket.write_nonblock data
    end
  end
  
  module BlockingRead
    def read_nonblock
      socket.readpartial MAX_BYTES_PER_READ
    end
  end
  module BlockingWrite
    def write_nonblock data
      socket.write data
    end
  end
end
