# -*- encoding: utf-8 -*-

class OnStomp::OpenURI::MessageQueue
  def initialize
    @queue = []
    @queue.extend MonitorMixin
    @empty_check = @queue.new_cond
  end
  
  def shift
    take_from_queue :shift
  end
  
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
