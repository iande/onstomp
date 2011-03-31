# -*- encoding: utf-8 -*-

class OnStomp::Failover::Pools::RoundRobin < OnStomp::Failover::Pools::Base
  def initialize uris
    super
    @index = -1
  end

  def next_client
    @index = (@index + 1) % clients.size
    clients[@index]
  end
end
