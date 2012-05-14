# -*- encoding: utf-8 -*-

# Mixin for event management.
module OnStomp::Interfaces::EventManager
  # Extends base with {OnStomp::Interfaces::EventManager::ClassMethods}
  def self.included(base)
    base.extend ClassMethods
  end
  
  # Binds a `Proc` to be invoked when the given `event_name` is triggered.
  # @param [Symbol] event_name
  # @param [Proc] cb_proc
  # @return [self]
  def bind_event(event_name, cb_proc)
    event_callbacks[event_name] << cb_proc
    self
  end
  
  # Returns a hash of event names mapped to arrays of proc callbacks.
  # @return [{Symbol => Array<Proc>}]
  def event_callbacks
    @event_callbacks ||= Hash.new { |h, k| h[k] = [] }
  end
  
  # Triggers an event by the given name, passing along any additional
  # `args` as parameters to the callback
  # @param [Symbol] event_name event to trigger
  # @param [Object, Object, ...] args
  def trigger_event(event_name, *args)
    event_callbacks[event_name].each do |cb|
      begin
        cb.call(*args)
      rescue Exception => ex
        warn "[OnStomp/Event] triggering #{event_name} raised an error: #{ex}"
      end
    end
  end
  
  # Mixin to allow includers to define custom event methods
  module ClassMethods
    # A convenient way to get a list of all of the event methods a class
    # has defined for itself. Returns an array of event method names as symbols.
    # @return [Array<Symbol>]
    def event_methods
      @event_methods ||= []
    end
    
    # Creates a convenience method for binding callbacks to the given
    # event name.
    # @param [Symbol] name
    # @example
    #   class ExampleClass
    #     include OnStomp::Interfaces::EventManager
    #
    #     create_event_method :do_event
    #   end
    #
    #   example_obj.do_event { |arg1, arg2| ... }
    def create_event_method name
      event_methods << name
      module_eval "def #{name}(&block); bind_event(:#{name}, block); end"
    end

    # Creates convenience methods for binding callbacks to the given
    # event name with a set of prefixes.
    # @param [Symbol] name
    # @param [Symbol, Symbol, ...] prefixes (eg: :on, :before, :after)
    # @example
    #   class ExampleClass
    #     include OnStomp::Interfaces::EventManager
    #
    #     create_event_methods :some_event, :before, :during, :after
    #   end
    #
    #   example_obj.before_some_event { |arg| ... }
    #   example_obj.after_some_event { |arg| ... }
    #   example_obj.during_some_event { |arg| ... }
    def create_event_methods name, *prefixes
      prefixes << :on if prefixes.empty?
      prefixes.each { |pre| create_event_method :"#{pre}_#{name}" }
    end
  end
end
