# -*- encoding: utf-8 -*-

# Module for event based extensions.
module OnStomp::Interfaces::EventManager  
  # Transmitted frame events (on_<frame>, before_<frame>)
  [ :ack, :nack, :begin, :abort, :commit, :send,
    :subscribe, :unsubscribe, :disconnect, :client_beat ].each do |ev|
    module_eval <<-EOS
      def before_#{ev}(&block); bind_callback(:before_#{ev}, block); end
      def on_#{ev}(&block); bind_callback(:on_#{ev}, block); end
    EOS
  end
  
  # Received frame events (on_<frame>)
  [ :error, :message, :receipt, :broker_beat ].each do |ev|
    module_eval <<-EOS
      def on_#{ev}(&block); bind_callback(:on_#{ev}, block); end
    EOS
  end
  
  # General frame events (before_<event>, after_<event>)
  [ :transmitting, :receiving ].each do |ev|
    module_eval <<-EOS
      def before_#{ev}(&block); bind_callback(:before_#{ev}, block); end
      def after_#{ev}(&block); bind_callback(:after_#{ev}, block); end
    EOS
  end
  
  # Connection events (on_connection_<event>)
  [ :established, :closed, :died, :terminated ].each do |ev|
    module_eval <<-EOS
      def on_connection_#{ev}(&block); bind_callback(:on_connection_#{ev}, block); end
    EOS
  end
  
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
  
  def trigger_frame_event f, pref, origin
    e = f.command ? :"#{pref}_#{f.command.downcase}" :
      :"#{pref}_#{origin}_beat"
    trigger_event e, f, self
  end
  
  def trigger_connection_event event
    trigger_event :"on_connection_#{event}", self
  end
  
  def trigger_before_receiving f
    trigger_event :before_receiving, f, self
  end
  
  def trigger_after_receiving f
    trigger_event :after_receiving, f, self
    trigger_frame_event f, :on, :broker
  end
  
  def trigger_before_transmitting f
    trigger_event :before_transmitting, f, self
    trigger_frame_event f, :before, :client
  end
  
  def trigger_after_transmitting f
    trigger_event :after_transmitting, f, self
    trigger_frame_event f, :on, :client
  end
end
