# -*- encoding: utf-8 -*-

# Mixin for event management.
module OnStomp::Interfaces::EventManager
  def self.included(base)
    base.extend ClassMethods
  end
  
  # Binds a +Proc+ to be invoked when the given +event_name+ is triggered.
  # @param [Symbol] event_name
  # @param [Proc] cb_proc
  # @return [self]
  def bind_event(event_name, cb_proc)
    event_callbacks[event_name] << cb_proc
    self
  end
  
  def event_callbacks
    @event_callbacks ||= Hash.new { |h, k| h[k] = [] }
  end
  
  def trigger_event(event_name, *args)
    event_callbacks[event_name].each { |cb| cb.call(*args) }
  end
  
  module ClassMethods
    def create_event_method name
      module_eval "def #{name}(&block); bind_event(:#{name}, block); end"
    end

    def create_event_methods name, *prefixes
      prefixes << :on if prefixes.empty?
      prefixes.each { |pre| create_event_method :"#{pre}_#{name}" }
    end
  end
end
