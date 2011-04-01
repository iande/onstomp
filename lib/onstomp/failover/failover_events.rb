# -*- encoding: utf-8 -*-

module OnStomp::Failover::FailoverEvents
  include OnStomp::Interfaces::EventManager
  
  # We do this one using +class << self+ instead of the +self.included+ hook
  # because we need 'create_client_event_method+ immediately.
  class << self
    def create_client_event_method name
      module_eval "def #{name}(&block); bind_client_event(:#{name}, block); end"
    end
  end
  
  OnStomp::Interfaces::ClientEvents.event_methods.each do |ev|
    create_client_event_method ev
  end
  
  def on_connection_established &block
    bind_client_event(:on_connection_established, block)
  end
  def on_connection_died &block
    bind_client_event(:on_connection_died, block)
  end
  def on_connection_terminated &block
    bind_client_event(:on_connection_terminated, block)
  end
  def on_connection_closed &block
    bind_client_event(:on_connection_closed, block)
  end
  
  def bind_client_event(name, block)
    client_pool.each do |client|
      client.__send__ name do |*args|
        if client == active_client
          block.call *args
        end
      end
    end
  end
  
  create_event_methods :failover_retry, :before, :after
  create_event_methods :failover_connect_failure, :on
  create_event_methods :failover_retries_exceeded, :on
  create_event_methods :failover_lost, :on
  create_event_methods :failover_connected, :on
  
  def trigger_failover_retry pref, attempt
    trigger_failover_event :retry, pref, attempt, self.active_client
  end
  
  def trigger_failover_event ev, pref, *args
    trigger_event :"#{pref}_failover_#{ev}", self, *args
  end
end
