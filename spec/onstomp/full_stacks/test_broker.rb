# -*- encoding: utf-8 -*-

# This is meant to provide basic testing of the full IO of an OnStomp client.
# It is not designed to handle more than one client at a time.
class TestBroker
  class StopThread < StandardError; end
  
  attr_reader :messages, :sessions, :mau_dib
  attr_reader :frames_received, :frames_transmitted
  attr_accessor :session_class, :accept_delay
  
  def initialize(port=61613)
    @frames_received = []
    @frames_transmitted = []
    @sessions = []
    @messages = Hash.new { |h,k| h[k] = [] }
    @subscribes = Hash.new { |h,k| h[k] = [] }
    @sub_mutex = Mutex.new
    @session_mutex = Mutex.new
    @port = port
    begin
      @socket = TCPServer.new @port
    rescue Exception => ex
      $stdout.puts "Could not bind: #{ex}"
    end
    @session_class = Session10
    @accept_delay = nil
  end
    
  def kill_on_command command
    @mau_dib = command
  end
  
  def enqueue_message s
    @sub_mutex.synchronize do
      msg = OnStomp::Components::Frame.new 'MESSAGE', {}, s.body
      s.headers.each do |k,v|
        msg.headers.append k, v
      end
      msg[:'message-id'] = "msg-#{Time.now.to_f}"
      dest = msg[:destination]
      if !@subscribes[dest].empty?
        session, subid = @subscribes[dest].first
        deliver_message msg, session, subid
      else
        @messages[dest] << msg
      end
    end
  end
  
  def deliver_message msg, sess, subid
    msg[:subscription] = subid
    sess.transmit msg
  end
  
  def messages_for dest
    @messages[dest]
  end
  
  def bodies_for dest
    messages_for(dest).map { |m| m.body }
  end
  
  def subscribe f, session
    @sub_mutex.synchronize do
      #$stdout.puts "Subscribing?"
      dest = f[:destination]
      @subscribes[dest] << [session, f[:id]]
      #$stdout.puts "Any messages? #{@messages[dest].inspect}"
      until @messages[dest].empty?
        msg = @messages[dest].shift
        deliver_message msg, session, f[:id]
      end
    end
  end
  
  def unsubscribe f, session
    @sub_mutex.synchronize do
      @subscribes[f[:destination]].reject! do |pair|
        pair.first == session && pair.last == f[:id]
      end
    end
  end

  def start
    @listener = Thread.new do
      begin
        loop do
          sock = @socket.accept
          @accept_delay && sleep(@accept_delay)
          @session_mutex.synchronize do
            @sessions << @session_class.new(self, sock)
          end
        end
      rescue StopThread
      rescue Exception
        $stdout.puts "Listener failed: #{$!}"
        $stdout.puts $!.backtrace
        stop
      end
    end
  end
  
  def stop
    @session.stop if @session
    @listener.raise(StopThread.new) rescue nil
    @listener.join rescue nil
    @socket.close rescue nil
  end
  
  def join
    @sessions.each do |s|
      s.join
    end
  end
  
  class Session10
    include OnStomp::Interfaces::ClientEvents
    
    attr_reader :connection, :socket
    def initialize server, sock
      @server = server
      @socket = sock
      init_events
      init_connection
      connect_frame = nil
      @connection.io_process_read do |f|
        connect_frame ||= f
      end until connect_frame
      reply_to_connect connect_frame
    end
    
    def init_connection
      @connection = OnStomp::Connections::Stomp_1_0.new(socket, self)
      @processor = OnStomp::Components::ThreadedProcessor.new self
      @killing = false
      @session_killer = Thread.new do
        Thread.pass until @killing
        @socket.close rescue nil
        @processor.stop rescue nil
      end
    end
    
    def reply_to_connect connect_frame
      connected_frame = nil
      transmit OnStomp::Components::Frame.new('CONNECTED')
      @connection.io_process_write do |f|
        connected_frame ||= f
      end until connected_frame
      @processor.start
    end
    
    def connected?
      @connection.connected?
    end
    
    def init_events
      on_subscribe do |s,_|
        @server.subscribe(s, self) unless @killing
      end
      
      on_unsubscribe do |u, _|
        @server.unsubscribe(u, self) unless @killing
      end
      
      on_send do  |s,_|
        @server.enqueue_message(s) unless @killing
      end
      
      on_disconnect do |d,_|
        #@connection.close
      end
      
      after_transmitting do |f,_|
        @server.frames_transmitted << f
      end
      
      before_receiving do |f,_|
        @server.frames_received << f unless @killing
        if @server.mau_dib && f.command == @server.mau_dib
          kill
        elsif !@killing
          if f.header? :receipt
            transmit OnStomp::Components::Frame.new('RECEIPT',
              :'receipt-id' => f[:receipt])
          end
        end
      end
    end
    
    def dispatch_transmitted f
      trigger_after_transmitting f
    end
    
    def dispatch_received f
      trigger_before_receiving f
      trigger_after_receiving f
    end
    
    def transmit frame
      frame.tap do
        trigger_before_transmitting frame
        connection.write_frame_nonblock(frame)
      end
    end
    
    def join
      if @connection.connected?
        #@connection.close
        @processor.join rescue nil
      end
    end
    
    def kill
      @killing = true
    end
    
    def stop
      if @connection.connected?
        @connection.close
        @processor.stop
      end
    end
  end
  
  class Session11 < Session10
    def init_events
      super
    end
    
    def heartbeats; [3000, 10000]; end
    
    def reply_to_connect connect_frame
      connected_frame = nil
      transmit OnStomp::Components::Frame.new('CONNECTED',
        :version => '1.1', :'heart-beat' => heartbeats)
      @connection.io_process_write do |f|
        connected_frame ||= f
      end until connected_frame
      @connection = OnStomp::Connections::Stomp_1_1.new(@connection.socket, self)
      @connection.configure connect_frame, {}
      @processor.start
    end
  end
  
  class SessionCloseBeforeConnect
    def initialize server, sock
      sock.close rescue nil
    end
  end

  class SessionCloseAfterConnect < Session10
    def initialize server, sock
      @server = server
      @socket = sock
      init_events
      init_connection
      connect_frame = nil
      @connection.io_process_read do |f|
        connect_frame ||= f
      end until connect_frame
      @socket.close
    end
  end

  class SessionTimeoutAfterConnect < Session10
    def initialize server, sock
      @server = server
      @socket = sock
      init_events
      init_connection
      connect_frame = nil
      @connection.io_process_read do |f|
        connect_frame ||= f
      end until connect_frame
      # Do not send a frame, do not close the connection, let it timeout
    end
  end

  class SessionBadFrameAfterConnect < Session10
    def initialize server, sock
      @server = server
      @socket = sock
      init_events
      init_connection
      connect_frame = nil
      @connection.io_process_read do |f|
        connect_frame ||= f
      end until connect_frame
      reply_to_connect_with_crap
    end

    def reply_to_connect_with_crap
      connected_frame = nil
      transmit OnStomp::Components::Frame.new('CRAPPY_FRAME')
      @connection.io_process_write do |f|
        connected_frame ||= f
      end until connected_frame
    end
  end

  class StompErrorOnConnectSession < Session10
  end
end

class TestSSLBroker < TestBroker
  SSL_CERT_FILES = {
    :default => {
      :c => File.expand_path('../ssl/broker_cert.pem', __FILE__),
      :k => File.expand_path('../ssl/broker_key.pem', __FILE__)
    }
  }
  
  def initialize(port=61612, certs=:default)
    super(port)
    @tcp_socket = @socket
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    cert_files = SSL_CERT_FILES[certs]
    @ssl_context.key = OpenSSL::PKey::RSA.new(File.read(cert_files[:k]))
    @ssl_context.cert = OpenSSL::X509::Certificate.new(File.read(cert_files[:c]))
    @socket = OpenSSL::SSL::SSLServer.new(@tcp_socket, @ssl_context)
    @socket.start_immediately = true
    @session = nil
  end
end
