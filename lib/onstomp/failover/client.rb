# -*- encoding: utf-8 -*-

# A failover client that wraps multiple {OnStomp::Client clients} and maintains
# a connection to one of these clients. Frames are sent to the currently
# connected client. If the connection is lost, a failover client will
# automatically reconnect to another client in the pool, re-transmit any
# necessary frames and resume operation.
class OnStomp::Failover::Client
  include OnStomp::Failover::FailoverConfigurable
  include OnStomp::Failover::FailoverEvents
  include OnStomp::Interfaces::FrameMethods
  
  # The class to use when instantiating a new {#client_pool}.
  # Defaults to {OnStomp::Failover::Pools::RoundRobin}
  # @return [Class]
  attr_configurable_pool :pool
  # The class to use when instantiating a new frame buffer.
  # Defaults to {OnStomp::Failover::Buffers::Written}
  # @return [Class]
  attr_configurable_buffer :buffer
  # The delay in seconds to wait between connection retries.
  # Defaults to +10+.
  # @return [Fixnum]
  attr_configurable_int :retry_delay, :default => 10
  # The maximum number of times to retry connecting during a reconnect
  # loop. A non-positive number will force the failover client to try to
  # reconnect indefinitely. Defaults to +0+
  # @return [Fixnum]
  attr_configurable_int :retry_attempts, :default => 0
  # Whether or not to randomize the {#client_pool} before connecting through
  # any of its {OnStomp::Client clients}. Defaults to `false`
  # @return [true,false]
  attr_configurable_bool :randomize, :default => false
  
  attr_reader :uri, :client_pool, :active_client, :frame_buffer, :connection
  
  def initialize(uris, options={})
    @uri = OnStomp::Failover::URI::FAILOVER.parse uris
    @client_mutex = Mutex.new
    configure_configurable options
    create_client_pool
    @active_client = nil
    @connection = nil
    @frame_buffer = buffer.new self
    @disconnecting = false
  end
  
  # Returns true if there is an {#active_client} and it is
  # {OnStomp::Client#connected? connected}.
  # @return [true,false,nil]
  def connected?
    active_client && active_client.connected?
  end

  # Transmits a frame to the {#active_client} if one exists.
  # @return [OnStomp::Components::Frame,nil]
  def transmit frame, cbs={}
    active_client && active_client.transmit(frame, cbs)
  end
  
  # Connects to one of the clients in the {#client_pool}
  # @return [self]
  def connect
    @disconnecting = false
    unless reconnect
      raise OnStomp::Failover::MaximumRetriesExceededError
    end
    self
  end
  
  # Ensures that a connection is properly established, then invokes
  # {OnStomp::Client#disconnect disconnect} on the {#active_client}
  def disconnect *args, &block
    return unless active_client
    # If we're not connected, let `reconnect` handle it.
    #@disconnecting = [args, block]
    #if connected?
      @client_mutex.synchronize do
        @disconnecting = true
        active_client.disconnect *args, &block
      end
    #end
  end
  
  private
  def reconnect
    @client_mutex.synchronize do
      attempt = 1
      until connected? || retry_exceeded?(attempt)
        sleep_for_retry attempt
        begin
          trigger_failover_retry :before, attempt
          @active_client = client_pool.next_client
          # `reconnect` could be called again within the marked range.
          active_client.connect # <--- From here
          @connection = active_client.connection
        rescue Exception
          trigger_failover_event :connect_failure, :on, active_client, $!.message
        end
        trigger_failover_retry :after, attempt
        attempt += 1
      end
      connected?.tap do |b|
        b && trigger_failover_event(:connected, :on, active_client)
        #if @disconnecting.is_a?(Array)
        #  args, block = @disconnect
        #  active_client.disconnect *args, &block
        #end
      end # <--- Until here
    end
  end
  
  def retry_exceeded? attempt
    retry_attempts > 0 && attempt > retry_attempts
  end
  
  def sleep_for_retry attempt
    sleep(retry_delay) if retry_delay > 0 && attempt > 1
  end
    
  def create_client_pool
    @client_pool = pool.new(uri.failover_uris)
    on_connection_closed do |client, *_|
      unless @disconnecting
        trigger_failover_event(:lost, :on, active_client)
        reconnect
      end
    end
  end
end
