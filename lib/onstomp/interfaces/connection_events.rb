# -*- encoding: utf-8 -*-

# Mixin for connection events
module OnStomp::Interfaces::ConnectionEvents
  include OnStomp::Interfaces::EventManager

  # Connection events (on_connection_<event>)
  [ :established, :closed, :died, :terminated ].each do |ev|
    module_eval <<-EOS
      def on_#{ev}(&block); bind_callback(:on_#{ev}, block); end
    EOS
  end
  
  def trigger_connection_event event
    trigger_event :"on_#{event}", self.client, self
  end
  
  def install_bindings_from_client ev_hash
    ev_hash.each do |ev, cbs|
      cbs.each { |cb| bind_callback(ev, cb) }
    end
    trigger_connection_event :connected
  end
end
