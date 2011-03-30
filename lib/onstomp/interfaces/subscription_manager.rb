# -*- encoding: utf-8 -*-

# Mixin for {OnStomp::Client clients} to provide receipt management
module OnStomp::Interfaces::SubscriptionManager
  # Returns an array of {OnStomp::Components::Subscription} objects for all
  # currently active subscriptions.
  # @return [Array<OnStomp::Components::Subscription>]
  def subscriptions
    @subcription_mon.synchronize { @subscriptions.values }
  end
  
  private
  def configure_subscription_management
    @subcription_mon = Monitor.new
    @subscriptions = {}
    on_message { |m, c| dispatch_subscription m }
    on_unsubscribe { |u, c| remove_subscription u[:id] }
  end
  
  def add_subscription f, cb
    s_id = f[:id]
    dest = f[:destination]
    @subcription_mon.synchronize do
      @subscriptions[s_id] = OnStomp::Components::Subscription.new(f, cb)
    end
  end

  def remove_subscription sub_id
    @subcription_mon.synchronize do
      @subscriptions.delete sub_id
    end
  end
  
  def clear_subscriptions
    @subcription_mon.synchronize { @subscriptions.clear }
  end
  
  def dispatch_subscription m
    if m.header? :subscription
      sub = @subcription_mon.synchronize { @subscriptions[m[:subscription]] }
      sub && sub.call(m)
    else
      @subcription_mon.synchronize do
        @subscriptions.values.select { |sub| sub.include? m }
      end.each { |sub| sub.call m }
    end
  end
end
