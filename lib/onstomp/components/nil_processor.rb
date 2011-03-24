# -*- encoding: utf-8 -*-

# A processor that does nothing!
class OnStomp::Components::NilProcessor
  def initialize(client); end
  def running?; false; end
  def start; self; end
  def join; self; end
  def stop; self; end
end
