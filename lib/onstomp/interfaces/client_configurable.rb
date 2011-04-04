# -*- encoding: utf-8 -*-

# Module for configurable attributes specific to {OnStomp::Client client} objects.
module OnStomp::Interfaces::ClientConfigurable
  # Includes {OnStomp::Interfaces::UriConfigurable} into `base` and
  # extends {OnStomp::Interfaces::ClientConfigurable::ClassMethods}
  # @param [Module] base
  def self.included(base)
    base.__send__ :include, OnStomp::Interfaces::UriConfigurable
    base.extend ClassMethods
  end
  
  # Provides attribute methods for {OnStomp::Client client} objects.
  module ClassMethods
    # Creates a readable and writeable attribute with the given name that
    # defaults to the {OnStomp::Connections.supported supported} protocol
    # versions and is {OnStomp::Connections.select_supported filtered} to
    # those versions when assigned. Corresponds to which protocol versions
    # should be used for a given client's connection.
    # @param [Symbol] nm name of attribute
    def attr_configurable_protocols nm
      attr_configurable_arr(nm, :default => OnStomp::Connections.supported) do |vers|
        OnStomp::Connections.select_supported(vers).tap do |valid|
          raise OnStomp::UnsupportedProtocolVersionError, vers.inspect if valid.empty?
        end
      end
    end
    
    # Creates a readable and writeable attribute with the given name that
    # defaults to [0, 0] and is mapped to a pair of non-negative integers
    # when assigned. Corresponds to what heartbeating strategy should be used
    # for a given client's connection where [0, 0] indicates no heartbeating
    # should be performed.
    # @note This attribute is only useful with STOMP 1.1 connections.
    # @param [Symbol] nm name of attribute
    def attr_configurable_client_beats nm
      attr_configurable_arr(nm, :default => [0,0]) do |val|
        val.map { |b| bi = b.to_i; bi < 0 ? 0 : bi }
      end
    end
    
    # Creates a readable and writeable attribute with the given name that
    # defaults to the {OnStomp::Components::ThreadedProcessor}. Corresponds
    # the the class to use when create new processor instances when a client
    # is connected.
    # @param [Symbol] nm name of attribute
    def attr_configurable_processor nm
      attr_configurable_class(nm, :default => OnStomp::Components::ThreadedProcessor)
    end
  end
end
