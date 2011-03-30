# -*- encoding: utf-8 -*-

# Adds the a set of headers to all frames generated on the scope.
class OnStomp::Components::Scopes::HeaderScope
  include OnStomp::Interfaces::FrameMethods
  
  attr_reader :headers, :client, :connection
  
  def initialize headers, client
    @headers = headers
    @client = client
    @connection = client.connection
  end
  
  # Wraps {OnStomp::Client#transmit}, applying the set of {#headers} to
  # all frames befor they are delivered to the broker.
  # @param [OnStomp::Components::Frame] frame
  # @param [{Symbol => Proc}] cbs
  # @return [OnStomp::Components::Frame]
  # @see OnStomp::Client#transmit
  def transmit frame, cbs={}
    frame.headers.reverse_merge!(headers)
    client.transmit frame, cbs
  end
end
