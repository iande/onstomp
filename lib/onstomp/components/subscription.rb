# -*- encoding: utf-8 -*-

# A simple encapsulation of a subscription. Instances of this class keep
# track of the SUBSCRIBE frame they were generated for and the callback to
# invoke when a MESSAGE frame is received for the subscription.
class OnStomp::Components::Subscription
  attr_reader :frame, :callback
  # Creates a new subscription
  # @param [OnStomp::Components::Frame] fr the subscription's SUBSCRIBE frame
  # @param [Proc] cb the subscription's callback
  def initialize(fr, cb)
    @frame = fr
    @callback = cb
  end
  # Returns the `id` header of the associated SUBSCRIBE frame
  # @return [String]
  def id; frame[:id]; end
  # Returns the `destination` header of the associated SUBSCRIBE frame
  # @return [String]
  def destination; frame[:destination]; end
  # Invokes the {#callback}, passing along the supplied MESSAGE frame
  # @param [OnStomp::Componenets::Frame] m the associated MESSAGE frame
  def call(m); callback.call(m); end
  # Returns true if this message frame shares the same destination as this
  # subscription, false otherwise.
  # @return [true, false]
  def include? m
    self.destination == m[:destination]
  end
end
