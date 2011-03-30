# -*- encoding: utf-8 -*-

# A processor that does nothing, used in the event that
# {OnStomp::Client client} +processor+ attribute is set to +nil+
class OnStomp::Components::NilProcessor
  # Creates a new processor
  def initialize(client); end
  # Always returns +false+
  # @return [false]
  def running?; false; end
  # Does nothing
  # @return [self]
  def start; self; end
  # Does nothing
  # @return [self]
  def join; self; end
  # Does nothing
  # @return [self]
  def stop; self; end
end
