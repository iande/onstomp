# -*- encoding: utf-8 -*-

# An IO processor that does its work on its own thread. 
class OnStomp::Components::ThreadedProcessor
  # Creates a new processor for the {OnStomp::Client client}
  # @param [OnStomp::Client] client
  def initialize client
    @client = client
    @run_thread = nil
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
        end
      rescue OnStomp::StopReceiver
      rescue Exception
        raise
      end
    end
    self
  end
  
  # Causes the thread this method was invoked in to +pass+ until the
  # processor is no longer {#running? running}.
  # @return [self]
  def join
    Thread.pass while running?
    self
  end
  
  # Forcefully stops the processor and joins its IO thread to the
  # callee's thread.
  # @return [self]
  # @raise [IOError, SystemCallError] if either were raised in the IO thread
  #   and the {OnStomp::Client client} is still
  #   {OnStomp::Client#connected? connected} after the thread is joined.
  def stop
    begin
      @run_thread.raise OnStomp::StopReceiver if @run_thread.alive?
      @run_thread.join
    rescue IOError, SystemCallError
      raise if @client.connected?
    end
    @run_thread = nil
    self
  end
end
