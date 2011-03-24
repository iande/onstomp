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
        while @client.alive?
          @client.connection.single_io_cycle
        end
      rescue OnStomp::StopReceiver
      rescue Exception
        #$stdout.puts "What the crap?: #{$!}"
        #$stdout.puts $!.backtrace
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
      raise if @client.alive?
    end
    @run_thread = nil
    self
  end
end
