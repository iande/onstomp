# -*- encoding: utf-8 -*-

# Module for configurable attributes specific to {OnStomp::Client} objects.
module OnStomp::Interfaces::ClientConfigurable
  def self.included(base)
    base.__send__ :include, OnStomp::Interfaces::UriConfigurable
    base.extend ClassMethods
  end
  
  module ClassMethods
    def attr_configurable_protocols nm
      attr_configurable_arr(nm, :default => OnStomp::Connections.supported) do |vers|
        OnStomp::Connections.select_supported(vers).tap do |valid|
          raise OnStomp::UnsupportedProtocolVersionError, vers.inspect if valid.empty?
        end
      end
    end
  
    def attr_configurable_client_beats nm
      attr_configurable_arr(nm, :default => [0,0]) do |val|
        val.map { |b| bi = b.to_i; bi < 0 ? 0 : bi }
      end
    end
    
    def attr_configurable_receiver nm
      attr_configurable_class(nm, :default => OnStomp::Components::ThreadedReceiver)
    end
  end
end
