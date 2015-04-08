# -*- encoding: utf-8 -*-

# An abstract pool of clients. This class manages the shared behaviors
# of client pools, but has no means of picking successive clients.
# Subclasses must define `next_client` or pool will not function.
class OnStomp::Failover::Pools::Base
  attr_reader :clients
  
  # Creates a new client pool by mapping an array of URIs into an array of
  # {OnStomp::Client clients}.
  def initialize hosts, options = {}
    @clients = hosts.map do |h|
      h.is_a?(OnStomp::Client) ? h : OnStomp::Client.new(h, options)
    end
  end
  
  # Raises an error, because it is up to subclasses to define this behavior.
  # @raise [StandardError]
  def next_client
    raise 'implemented in subclasses'
  end
  
  # Shuffles the client pool.
  def shuffle!
    clients.shuffle!
  end
  
  # Yields each client in the pool to the supplied block. Raises an error
  # if no block is provided.
  # @raise [ArgumentError] if no block is given
  # @yield [client] block to call for each client in the pool
  # @yieldparam [OnStomp::Client] client
  # @return [self]
  def each &block
    raise ArgumentError, 'no block provided' unless block_given?
    clients.each &block
    self
  end
end
