# -*- encoding: utf-8 -*-

# Module for configurable attributes specific to
# {OnStomp::Failover::Client failover} clients.
module OnStomp::Failover::FailoverConfigurable
  # Includes {OnStomp::Interfaces::ClientConfigurable} into +base+ and
  # extends {OnStomp::Failover::FailoverConfigurable::ClassMethods}
  # @param [Module] base
  def self.included(base)
    base.__send__ :include, OnStomp::Interfaces::ClientConfigurable
    base.extend ClassMethods
  end
  
  # Provides attribute methods for {OnStomp::Failover::Client failover}
  # clients.
  module ClassMethods
    def attr_configurable_int *args, &block
      trans = __attr_configurable_wrap__ lambda { |v| v.to_i }, block
      attr_configurable_single(*args, &trans)
    end
    
    def attr_configurable_bool *args, &block
      trans = __attr_configurable_wrap__ lambda { |v|
        [true, 'true', '1', 1].include?(v) }, block
      attr_configurable_single(*args, &trans)
      args.each do |a|
        unless a.is_a?(Hash)
          alias_method :"#{a}?", a
        end
      end
    end
    
    def attr_configurable_pool nm
      attr_configurable_class(nm,
        :default => OnStomp::Failover::Pools::RoundRobin) do |pr|
        pr || OnStomp::Failover::Pools::RoundRobin
      end
    end
  end
end
