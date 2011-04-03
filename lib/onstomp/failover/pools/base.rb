# -*- encoding: utf-8 -*-

# Subclasses must define +next_client+ or pool will not function.
class OnStomp::Failover::Pools::Base
  attr_reader :clients
  
  def initialize uris
    @clients = uris.map do |u|
      OnStomp::Client.new u
    end
  end
  
  def next_client
    raise 'implemented in subclasses'
  end
  
  def shuffle!
    clients.shuffle!
  end
  
  def each &block
    raise ArgumentError, 'no block provided' unless block_given?
    clients.each &block
    self
  end
end
