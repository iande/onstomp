# -*- encoding: utf-8 -*-

# This class encapsulates a client connection to a message broker through the
# Stomp protocol.
class OnStomp::Client
  include OnStomp::Interfaces::ClientConfigurable
  include OnStomp::Interfaces::FrameMethods
  include OnStomp::Interfaces::EventManager
  include OnStomp::Interfaces::ReceiptManager
  include OnStomp::Interfaces::SubscriptionManager
  
  attr_reader :uri, :ssl, :connection
  
  # The protocol versions to allow for this connection
  # @return [Array<String>]
  attr_configurable_protocols :versions
  
  # The client-side heartbeat settings to allow for this connection
  # @return [Array<Fixnum>]
  attr_configurable_client_beats :heartbeats
  
  # The host header value to send to the broker when connecting. This allows
  # the client to inform the server which host it wishes to connect with
  # when multiple brokers may share an IP address through virtual hosting.
  # @return [String]
  attr_configurable_str :host, :default => 'localhost', :uri_attr => :host
  
  # The login header value to send to the broker when connecting.
  # @return [String]
  attr_configurable_str :login, :default => '', :uri_attr => :user
  
  # The passcode header value to send to the broker when connecting.
  # @return [String]
  attr_configurable_str :passcode, :default => '', :uri_attr => :password
  
  # The class to use when instantiating a new receiver for the connection.
  # Defaults to {OnStomp::Components::ThreadedReceiver}
  # @return [Class]
  attr_configurable_receiver :receiver
  
  def initialize(uri, options={})
    @uri = uri.is_a?(::URI) ? uri : ::URI.parse(uri)
    @ssl = options.delete(:ssl)
    configure_configurable options
    configure_subscription_management
    configure_receipt_management
    @disconnected = false
    on_disconnect do |f, con|
      @disconnected = true
      close unless f[:receipt]
    end
    @trans_queue = []
    @trans_mutex = Mutex.new
  end
  
  def connect(headers={})
    @connection = OnStomp::Connections.create_for(self)
    @disconnected = false
    begin
      @connection = connection.connect(self, headers, connect_headers)
    rescue
      disconnect
      raise
    end
    trigger_connection_event :established
    start_receiver
  end
  alias :open :connect
  
  def disconnect_with_flush(headers={})
    disconnect_without_flush(headers).tap do
      join_receiver
    end
  end
  alias :disconnect_without_flush :disconnect
  alias :disconnect :disconnect_with_flush
  
  def alive?
    connection && connection.alive?
  end
  
  def close
    connection && connection.close
    trigger_connection_event(:terminated) unless @disconnected
    trigger_connection_event :closed
    clear_subscriptions
    clear_receipts
    @connecting = @disconnected = false
  end
  
  def close!
    close
    stop_receiver
  end
  
  def transmit(frame, cbs={})
    frame.tap do
      register_callbacks frame, cbs
      trigger_before_transmitting frame
      connection.write_frame_nonblock frame
    end
  end
  
  def dispatch_received frame
    trigger_before_receiving frame
    trigger_after_receiving frame
  end
  
  def dispatch_transmitted frame
    trigger_after_transmitting frame
  end
  
  private
  def register_callbacks f, cbs
    cbs[:subscribe] && add_subscription(f, cbs[:subscribe])
    cbs[:receipt] && add_receipt(f, cbs[:receipt])
  end

  def start_receiver
    if receiver
      @receiver_inst = receiver.new self
      @receiver_inst.start
    end
  end
  
  def stop_receiver
    if @receiver_inst
      @receiver_inst.stop
      @receiver_inst = nil
    end
  end
  
  def join_receiver
    @receiver_inst && @receiver_inst.join
  end
  
  def connect_headers
    {
      :'accept-version' => @versions.join(','),
      :host => @host,
      :'heart-beat' => @heartbeats.join(','),
      :login => @login,
      :passcode => @passcode
    }
  end
end

