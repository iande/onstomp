# -*- encoding: utf-8 -*-

# Module for configurable attributes specific to
# {OnStomp::Failover::Client failover} clients.
module OnStomp::Failover::FailoverConfigurable
  # Includes {OnStomp::Interfaces::ClientConfigurable} into `base` and
  # extends {OnStomp::Failover::FailoverConfigurable::ClassMethods}
  # @param [Module] base
  def self.included(base)
    base.__send__ :include, OnStomp::Interfaces::ClientConfigurable
    base.extend ClassMethods
  end
  
  # Provides attribute methods for {OnStomp::Failover::Client failover}
  # clients.
  module ClassMethods
    # Creates readable and writeable attributes that are automatically
    # converted into boolean values. Assigning the attributes any of
    # `true`, `'true'`, `'1'` or `1` will set the attribute to `true`, all
    # other values with be treated as `false`. This method will also alias
    # the reader methods with `attr_name?`
    def attr_configurable_bool *args, &block
      trans = attr_configurable_wrap lambda { |v|
        [true, 'true', '1', 1].include?(v) }, block
      attr_configurable_single(*args, &trans)
      args.each do |a|
        unless a.is_a?(Hash)
          alias_method :"#{a}?", a
        end
      end
    end
    
    # Creates a readable and writeable attribute with the given name that
    # defaults to the {OnStomp::Failover::Pools::RoundRobin}. Corresponds
    # the the class to use when creating new
    # {OnStomp::Failover::Client#client_pool client pools}.
    # @param [Symbol] nm name of attribute
    def attr_configurable_pool nm
      attr_configurable_class(nm,
        :default => OnStomp::Failover::Pools::RoundRobin) do |p|
        p || OnStomp::Failover::Pools::RoundRobin
      end
    end
    
    # Creates a readable and writeable attribute with the given name that
    # defaults to the {OnStomp::Failover::Buffers::Written}. Corresponds
    # the the class to use for frame buffering and de-buffering.
    # @param [Symbol] nm name of attribute
    def attr_configurable_buffer nm
      attr_configurable_class(nm,
        :default => OnStomp::Failover::Buffers::Written) do |b|
        b || OnStomp::Failover::Buffers::Written
      end
    end
  end
end
