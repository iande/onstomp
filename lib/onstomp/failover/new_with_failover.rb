# -*- encoding: utf-8 -*-

class OnStomp::Client
  class << self
    # Creates an alias chain for {OnStomp::Client.new} so that if
    # a failover: URI or an array of URIs are passed to the constructor,
    # a {OnStomp::Failover::Client failover} client is built instead.
    # @return [OnStomp::Client,OnStomp::Failover::Client]
    def new_with_failover(uri, options={})
      if uri.is_a?(Array) || uri.to_s =~ /^failover:/i
        OnStomp::Failover::Client.new(uri, options)
      else
        new_without_failover(uri, options)
      end
    end
    
    alias :new_without_failover :new
    alias :new :new_with_failover
  end
end
