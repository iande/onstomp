# -*- encoding: utf-8 -*-

class OnStomp::Components::ThreadedProcessor
  def initialize client
    @client = client
    @run_thread = nil
  end
  
  def running?
    @run_thread && @run_thread.alive?
  end

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
  
  def join
    Thread.pass while running?
    self
  end
  
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
