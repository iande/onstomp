# -*- encoding: utf-8 -*-

# Mixin for event management.
module OnStomp::Interfaces::EventManager
  # Binds a +Proc+ to be invoked when the given +event_name+ is triggered.
  # @param [Symbol] event_name
  # @param [Proc] cb_proc
  # @return [self]
  def bind_callback(event_name, cb_proc)
    event_callbacks[event_name] << cb_proc
    self
  end
  
  def event_callbacks
    @event_callbacks ||= Hash.new { |h, k| h[k] = [] }
  end
  
  def trigger_event(event_name, *args)
    event_callbacks[event_name].each { |cb| cb.call(*args) }
  end
end
