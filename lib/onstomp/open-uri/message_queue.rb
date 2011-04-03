# -*- encoding: utf-8 -*-

# A simple synchronized message queue used to handle yielding MESSAGE frames
# to {OnStomp::OpenURI::ClientExtensions#each} blocks.
class OnStomp::OpenURI::MessageQueue
  def initialize
    @queue = []
    @queue.extend MonitorMixin
    @empty_check = @queue.new_cond
  end
  
  # Waits until the queue contains at least one element, then takes it out
  # and returns it.
  def shift
    take_from_queue :shift
  end
  
  # Puts a new object into the queue.
  def push msg
    put_in_queue :push, msg
  end
  alias :<< :push
  
  private
  def put_in_queue meth, msg
    @queue.synchronize do
      @queue.send meth, msg
      @empty_check.signal
    end
  end
  
  def take_from_queue meth
    @queue.synchronize do
      @empty_check.wait_while { @queue.empty? }
      @queue.send meth
    end
  end
end
