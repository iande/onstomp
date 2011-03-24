# -*- encoding: utf-8 -*-

class OnStomp::Components::ThreadedReceiver  
  def initialize client
    @client = client
    @run_mutex = Mutex.new
    @run_thread = nil
  end
  
  def running?
    @run_thread && @run_thread.alive?
  end

  def start
    is_starting = @run_mutex.synchronize { !running? }
    if is_starting
      @run_thread = Thread.new do
        begin
          while @client.alive?
            @client.connection.single_io_cycle
          end
        rescue OnStomp::StopReceiver
        rescue Exception
          $stdout.puts "What the crap?: #{$!}"
          $stdout.puts $!.backtrace
          raise
        end
      end
    end
    self
  end
  
  def join
    Thread.pass while @run_thread && @run_thread.alive?
  end
  
  def stop
    stopped = @run_mutex.synchronize { @run_thread.nil? }
    unless stopped
      begin
        @run_thread.raise OnStomp::StopReceiver.new
        @run_thread.join if Thread.current != @run_thread
      rescue OnStomp::StopReceiver
      rescue IOError, SystemCallError
        raise if @client && @client.alive?
      end
      @run_thread = nil
    end
    self
  end
end
