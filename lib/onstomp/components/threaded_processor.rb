# -*- encoding: utf-8 -*-

# An IO processor that does its work on its own thread. 
class OnStomp::Components::ThreadedProcessor
  # Creates a new processor for the {OnStomp::Client client}
  # @param [OnStomp::Client] client
  def initialize client
    @client = client
    @run_thread = nil
    @closing = false
  end
  
  # Returns true if its IO thread has been created and is alive, otherwise
  # false.
  # @return [true,false]
  def running?
    @run_thread && @run_thread.alive?
  end

  # Starts the processor by creating a new thread that continually invokes
  # {OnStomp::Connections::Base#io_process} while the client is
  # {OnStomp::Client#connected? connected}.
  # @return [self]
  def start
    @run_thread = Thread.new do
      begin
        while @client.connected?
          @client.connection.io_process
          Thread.stop if @closing
        end
      rescue OnStomp::StopReceiver
      rescue Exception
        # FIXME: This is pretty hacky, too. The problem is one of race
        # conditions and how we access the connection.
        raise if @run_thread == Thread.current
      end
    end
    self
  end
  
  # Prepares the conneciton for closing by flushing its write buffer.
  def prepare_to_close
    if running?
      @closing = true
      Thread.pass until @run_thread.stop?
      @client.connection.flush_write_buffer
      @closing = false
      @run_thread.wakeup
    end
  end
  
  # Causes the thread this method was invoked in to `pass` until the
  # processor is no longer {#running? running}.
  # @return [self]
  def join
    Thread.pass while running?
    @run_thread && @run_thread.join
    self
  end
  
  # Forcefully stops the processor and joins its IO thread to the
  # callee's thread.
  # @return [self]
  # @raise [IOError, SystemCallError] if either were raised in the IO thread
  #   and the {OnStomp::Client client} is still
  #   {OnStomp::Client#connected? connected} after the thread is joined.
  def stop
    if @run_thread
      begin
        @run_thread.raise OnStomp::StopReceiver if @run_thread.alive?
        @run_thread.join
      rescue OnStomp::StopReceiver
      rescue IOError, SystemCallError
        raise if @client.connected?
      end
      @run_thread = nil
    end
    self
  end
end
