# -*- encoding: utf-8 -*-

class OnStomp::Components::Subscription
  attr_reader :frame, :callback
  def initialize(fr, cb)
    @frame = fr
    @callback = cb
  end
  def id; frame[:id]; end
  def destination; frame[:destination]; end
  def call(m); callback.call(m); end
  def include? m
    self.destination == m[:destination]
  end
end
