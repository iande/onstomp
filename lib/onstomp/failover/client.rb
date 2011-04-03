# -*- encoding: utf-8 -*-

class OnStomp::Failover::Client
  include OnStomp::Failover::FailoverConfigurable
  include OnStomp::Failover::FailoverEvents
  include OnStomp::Interfaces::FrameMethods
  
  attr_configurable_processor :processor
  attr_configurable_pool :pool
  attr_configurable_buffer :buffer
  attr_configurable_int :retry_delay, :default => 10
  attr_configurable_int :retry_attempts, :default => 0
  attr_configurable_bool :randomize, :default => false
  
  attr_reader :uri, :client_pool, :active_client, :frame_buffer, :connection
  
  def initialize(uris, options={})
    if uris.is_a?(Array)
      uris = "failover:(#{uris.map { |u| u.to_s }.join(',')})"
    end
    @client_mutex = Mutex.new
    @uri = URI.parse(uris)
    configure_configurable options
    create_client_pool
    @active_client = nil
    @connection = nil
    @frame_buffer = buffer.new self
    @disconnecting = false
    @client_ready = false
  end
  
  def connected?
    active_client && active_client.connected?
  end

  def transmit frame, cbs={}
    active_client && active_client.transmit(frame, cbs)
  end
  
  def connect
    @disconnecting = false
    unless reconnect
      raise OnStomp::Failover::MaximumRetriesExceededError
    end
    self
  end
  
  def disconnect *args, &block
    return unless active_client
    @disconnecting = true
    Thread.pass until @client_ready
    active_client.disconnect *args, &block
  end
  
  private
  def reconnect
    @client_mutex.synchronize do
      @client_ready = false
      attempt = 1
      until connected? || retry_exceeded?(attempt)
        sleep_for_retry attempt
        begin
          trigger_failover_retry :before, attempt
          @active_client = client_pool.next_client
          # +reconnect+ could be called again within the marked range.
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
        @client_ready = b
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
