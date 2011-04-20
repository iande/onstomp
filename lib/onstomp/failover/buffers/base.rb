# -*- encoding: utf-8 -*-

# The base class for all buffers. This class exists mostly as a factoring
# out of the code shared between the {OnStomp::Failover::Buffers::Written}
# and {OnStomp::Failover::Buffers::Receipts} buffers.
class OnStomp::Failover::Buffers::Base
  def initialize failover
    @failover = failover
    @buffer_mutex = Mutex.new
    @buffer = []
    @txs = {}
  end
  
  # Returns the number of frames currently sitting in the buffer.
  # @return [Fixnum]
  def buffered
    @buffer.length
  end
  
  private
  def add_to_buffer f, heads={}
    @buffer_mutex.synchronize do
      unless f.header? :'x-onstomp-failover-replay'
        f.headers.reverse_merge! heads        
        @buffer << f 
      end
    end
  end
  
  def add_to_transactions f, heads={}
    @txs[f[:transaction]] = true
    add_to_buffer f, heads
  end
  
  def remove_from_transactions f
    tx = f[:transaction]
    if @txs.delete tx
      @buffer_mutex.synchronize do
        @buffer.reject! { |bf| bf[:transaction] == tx }
      end
    end
  end
  
  def remove_subscribe_from_buffer f
    @buffer_mutex.synchronize do
      @buffer.reject! { |bf| bf.command == 'SUBSCRIBE' && bf[:id] == f[:id] }
    end
  end
  
  def replay_buffer client
    replay_frames = @buffer_mutex.synchronize do
      @buffer.select { |f| f[:'x-onstomp-failover-replay'] = '1'; true }
    end
    
    replay_frames.each do |f|
      client.transmit f
    end
  end
end
