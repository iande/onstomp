# -*- encoding: utf-8 -*-

# Adds a receipt callback to all receipt-able frames generated on this scope
class OnStomp::Components::Scopes::ReceiptScope
  include OnStomp::Interfaces::FrameMethods
  
  attr_reader :callback, :client, :connection
  
  def initialize callback, client
    @callback = callback
    @client = client
    @connection = client.connection
  end
  
  # Wraps {OnStomp::Client#transmit}, applying the {#callback} as a receipt
  # handler for all frames before they are sent to the broker.
  # @param [OnStomp::Components::Frame] frame
  # @param [{Symbol => Proc}] cbs
  # @return [OnStomp::Components::Frame]
  # @see OnStomp::Client#transmit
  def transmit frame, cbs={}
    cbs[:receipt] ||= callback
    client.transmit frame, cbs
  end
end
