# -*- encoding: utf-8 -*-

# This class encapsulates a client connection to a message broker through the
# Stomp protocol.
class OnStomp::Client
  include OnStomp::Interfaces::ClientConfigurable
  include OnStomp::Interfaces::FrameMethods
  include OnStomp::Interfaces::ClientEvents
  include OnStomp::Interfaces::ReceiptManager
  include OnStomp::Interfaces::SubscriptionManager
  include OnStomp::Components::Scopes
  
  # The `URI` reference to the STOMP broker
  # @return [String]
  attr_reader :uri
  # SSL options for the connection
  # @return {Symbol => Object}
  attr_reader :ssl
  # Connection object specific to the established STOMP protocol version
  # @return [OnStomp::Connections::Base]
  attr_reader :connection
  
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
  
  # The class to use when instantiating a new IO processor for the connection.
  # Defaults to {OnStomp::Components::ThreadedProcessor}
  # @return [Class]
  attr_configurable_processor :processor
  
  # The number of seconds to wait before a write-blocked connection is
  # considered dead. Defaults to 120 seconds.
  # @return [Fixnum]
  attr_configurable_int :write_timeout, :default => 120
  
  # The number of seconds to wait before a connection that is read-blocked
  # during the {OnStomp::Connections::Base#connect connect} phase is
  # considered dead. Defaults to 120 seconds.
  # @return [Fixnum]
  attr_configurable_int :read_timeout, :default => 120
  
  # @api gem:1 STOMP:1.0,1.1
  # Creates a new client for the specified uri and optional hash of options.
  # @param [String,URI] uri
  # @param [{Symbol => Object}] options
  def initialize uri, options={}
    @uri = uri.is_a?(::URI) ? uri : ::URI.parse(uri)
    @ssl = options.delete(:ssl)
    configure_configurable options
    configure_subscription_management
    configure_receipt_management
    on_disconnect do |f, con|
      close unless f[:receipt]
    end
  end
  
  # @api gem:1 STOMP:1.0,1.1
  # Connects to the STOMP broker referenced by {#uri}. Includes optional
  # headers in the CONNECT frame, if specified.
  # @param [{#to_sym => #to_s}] headers
  # @return [self]
  def connect headers={}
    # FIXME: This is a quick fix to force the Threaded IO processor to
    # complete its work before we establish a connection.
    processor_inst.stop
    @connection = OnStomp::Connections.connect self, headers,
      { :'accept-version' => @versions.join(','), :host => @host,
        :'heart-beat' => @heartbeats.join(','), :login => @login,
        :passcode => @passcode }, pending_connection_events,
      read_timeout, write_timeout
    processor_inst.start
    self
  end
  alias :open :connect
  
  # @api gem:1 STOMP:1.0,1.1
  # Sends a DISCONNECT frame to the broker and blocks until the connection
  # has been closed. This method ensures that all frames not yet sent to
  # the broker will get processed barring any IO exceptions.
  # @param [{#to_sym => #to_s}] headers
  # @return [OnStomp::Components::Frame] transmitted DISCONNECT frame
  def disconnect_with_flush headers={}
    processor_inst.prepare_to_close
    disconnect_without_flush(headers).tap do
      processor_inst.join
    end
  end
  alias :disconnect_without_flush :disconnect
  alias :disconnect :disconnect_with_flush
  
  # @api gem:1 STOMP:1.0,1.1
  # Returns true if a connection to the broker exists and itself is connected.
  # @return [true,false]
  def connected?
    connection && connection.connected?
  end
  
  # @api gem:1 STOMP:1.0,1.1
  # Forces the connection between broker and client closed.
  # @note Use of this method may result in frames never being sent to the
  #   broker. This method should only be used if {#disconnect} is not an
  #   option and the connection needs to be terminated immediately.
  # @return [self]
  def close!
    close
    processor_inst.stop
    self
  end
  
  # @group Methods you ought not use directly.
  
  # Ultimately sends a {OnStomp::Components::Frame frame} to the STOMP broker.
  # This method should not be invoked directly. Use the frame methods provided
  # by the {OnStomp::Interfaces:FrameMethod} interface.
  # @return [OnStomp::Components::Frame]
  def transmit frame, cbs={}
    frame.tap do
      register_callbacks frame, cbs
      trigger_before_transmitting frame
      connection && connection.write_frame_nonblock(frame)
    end
  end
  
  # Called by {#connection} when a frame has been read from the socket
  # connection to the STOMP broker.
  def dispatch_received frame
    trigger_before_receiving frame
    trigger_after_receiving frame
  end
  
  # Called by {#connection} when a frame has been written to the socket
  # connection to the STOMP broker.
  def dispatch_transmitted frame
    trigger_after_transmitting frame
  end
  
  # @endgroup
  
  private
  def register_callbacks f, cbs
    cbs[:subscribe] && add_subscription(f, cbs[:subscribe])
    cbs[:receipt] && add_receipt(f, cbs[:receipt])
  end
  
  def processor_inst
    @processor_inst ||= processor.new(self)
  end
  
  def close
    connection && connection.close
    clear_subscriptions
    clear_receipts
  end
end
