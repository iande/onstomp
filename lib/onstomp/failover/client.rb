# -*- encoding: utf-8 -*-

class OnStomp::Failover::Client
  include OnStomp::Failover::FailoverConfigurable
  include OnStomp::Failover::FailoverEvents
  include OnStomp::Failover::FrameMethods
  
  attr_configurable_processor :processor
  attr_configurable_pool :pool
  attr_configurable_int :retry_delay, :default => 10
  attr_configurable_int :retry_attempts, :default => 0
  attr_configurable_bool :randomize, :default => false
  
  attr_reader :subscription_manager
  attr_reader :transaction_manager
  attr_reader :uri, :client_pool, :active_client
  
  def initialize(uris, options={})
    if uris.is_a?(Array)
      uris = "failover:(#{uris.map { |u| u.to_s }.join(',')})"
    end
    @client_mutex = Mutex.new
    @uri = URI.parse(uris)
    configure_configurable options
    create_client_pool
    @active_client = nil
    @disconnecting = false
  end
  
  def connected?
    active_client && active_client.connected?
  end

  def transmit frame, cbs={}
    active_client && active_client.transmit(frame, cbs)
  end
  
  def connect
    @disconnecting = false
    with_an_active_client { true }
  end
  
  def disconnect_with_failover_shutdown *args, &block
    @disconnecting = true
    disconnect_without_failover_shutdown *args, &block
  end
  alias :disconnect_without_failover_shutdown :disconnect
  alias :disconnect :disconnect_with_failover_shutdown
  
  private
  def connection; active_client && active_client.connection; end
  
  def reconnect
    @client_mutex.synchronize do
      @retry_attempt = 1
      while retry_connection?
        begin
          trigger_failover_retry :before
          @active_client = client_pool.next_client
          active_client.connect
        rescue Exception
          trigger_failover_event :connect_failure, :on, active_client, $!
          active_client.close! rescue nil
        end
        trigger_failover_retry :after
        @retry_attempt += 1
        sleep_for_retry if retry_connection?
      end
      connected?
    end
  end
  
  def sleep_for_retry
    sleep(retry_delay) if retry_delay > 0
  end
  
  def attempts_remaining
    retry_attempts < 1 ? 1 : (retry_attempts - @retry_attempt)
  end
  
  def retry_connection?
    !connected? && attempts_remaining > 0
  end
  
  def replay_connection
  end
  
  def with_an_active_client
    if connected? || reconnect
      yield
    else
      active_client && active_client.close! rescue nil
      raise OnStomp::Failover::MaximumRetriesExceededError,
        "retried #{@retry_attempt} times"
    end
  end
  
  def create_client_pool
    @client_pool = pool.new(uri.failover_uris)
    client_pool.each do |client|
      # This can happen on a separate thread... but, this will ONLY happen
      # on a separate thread... we should be just fine.
      client.on_connection_closed do |cl, con|
        unless @disconnecting || cl != active_client
          reconnect && replay_connection
        end
      end
    end
  end
end
