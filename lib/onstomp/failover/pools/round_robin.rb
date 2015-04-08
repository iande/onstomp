# -*- encoding: utf-8 -*-

# A round-robin client pool. Clients are processed sequentially, and once
# all clients have been processed, the pool cycles back to the beginning.
class OnStomp::Failover::Pools::RoundRobin < OnStomp::Failover::Pools::Base
  def initialize uris, options = {}
    super
    @index = -1
  end

  # Returns the next sequential client in the pool
  # @return [OnStomp::Client]
  def next_client
    @index = (@index + 1) % clients.size
    clients[@index]
  end
end
