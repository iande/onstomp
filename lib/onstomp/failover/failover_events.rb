# -*- encoding: utf-8 -*-

# Events mixin for {OnStomp::Failover::Client failover} clients.
module OnStomp::Failover::FailoverEvents
  include OnStomp::Interfaces::EventManager
  
  # We do this one using `class << self` instead of the `self.included` hook
  # because we need `create_client_event_method` immediately.
  class << self
    # Creates a forwarded binding for client events.
    def create_client_event_method name
      module_eval "def #{name}(&block); bind_client_event(:#{name}, block); end"
    end
  end
  
  # Create forwarded bindings for all {OnStomp::Client} events.
  OnStomp::Interfaces::ClientEvents.event_methods.each do |ev|
    create_client_event_method ev
  end
  
  # Binds a callback to {OnStomp::Client#on_connction_established}. This has
  # to be handled directly because :on_connection_established isn't a true
  # event.
  def on_connection_established &block
    bind_client_event(:on_connection_established, block)
  end
  # Binds a callback to {OnStomp::Client#on_connection_died}. This has
  # to be handled directly because :on_connection_died isn't a true
  # event.
  def on_connection_died &block
    bind_client_event(:on_connection_died, block)
  end
  # Binds a callback to {OnStomp::Client#on_connection_terminated}. This has
  # to be handled directly because :on_connection_terminated isn't a true
  # event.
  def on_connection_terminated &block
    bind_client_event(:on_connection_terminated, block)
  end
  # Binds a callback to {OnStomp::Client#on_connection_closed}. This has
  # to be handled directly because :on_connection_closed isn't a true
  # event.
  def on_connection_closed &block
    bind_client_event(:on_connection_closed, block)
  end
  
  # Sets up a forwarded event binding, applying it to all clients in 
  # {OnStomp::Failover::Client#client_pool}.
  def bind_client_event(name, block)
    client_pool.each do |client|
      client.__send__ name do |*args|
        if client == active_client
          block.call *args
        end
      end
    end
  end
  
  # Binds a callback to be invoked when a failover client is attempting to
  # connect through a new {OnStomp::Client client} in its
  # {OnStomp::Failover::Client#pool}.
  # @yield [failover, attempt, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Failover::Client] failover
  # @yieldparam [Fixnum] attempt
  # @yieldparam [OnStomp::Client] client
  create_event_methods :failover_retry, :before, :after
  # Binds a callback to be invoked when a failover client fails to establish
  # a connection through a {OnStomp::Client client} while reconnecting.
  # @yield [failover, client, error_message] callback invoked when event is triggered
  # @yieldparam [OnStomp::Failover::Client] failover
  # @yieldparam [OnStomp::Client] client
  # @yieldparam [String] error_message
  create_event_methods :failover_connect_failure, :on
  #create_event_methods :failover_retries_exceeded, :on
  # Binds a callback to be invoked when an established connection through a
  # client is lost.
  # @yield [failover, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Failover::Client] failover
  # @yieldparam [OnStomp::Client] client
  create_event_methods :failover_lost, :on
  # Binds a callback to be invoked when a connection through a
  # client is established.
  # @yield [failover, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Failover::Client] failover
  # @yieldparam [OnStomp::Client] client
  create_event_methods :failover_connected, :on
  # Binds a callback to be invoked when the maximum retries has been
  # exceeded.
  # @yield [failover] callback invoked when event is triggered
  # @yieldparam [OnStomp::Failover::Client] failover
  create_event_methods :failover_retries_exceeded, :on
  
  # Triggers a failover retry event
  def trigger_failover_retry pref, attempt
    trigger_failover_event :retry, pref, attempt, self.active_client
  end
  
  # Triggers a general failover event
  def trigger_failover_event ev, pref, *args
    trigger_event :"#{pref}_failover_#{ev}", self, *args
  end
end
