# -*- encoding: utf-8 -*-

# A buffer that ensures frames are RECEIPTed against a
# {OnStomp::Client client}'s {OnStomp::Connections::Base connection} and
# replays the ones that were not when the
# {OnStomp::Failover::Client failover} client reconnects.
# @todo Quite a lot of this code is shared between Written and Receipts,
#   we'll want to factor the common stuff out.
class OnStomp::Failover::Buffers::Receipts
  def initialize failover
    @failover = failover
    @buffer_mutex = Mutex.new
    @buffer = []
    @txs = {}
    
    failover.before_send &method(:buffer_frame)
    failover.before_commit &method(:buffer_frame)
    failover.before_abort &method(:buffer_frame)
    failover.before_subscribe &method(:buffer_frame)
    failover.before_begin &method(:buffer_transaction)
    # We can scrub the subscription before UNSUBSCRIBE is fully written
    # because if we replay before UNSUBSCRIBE was sent, we still don't
    # want to be subscribed when we reconnect.
    failover.before_unsubscribe &method(:debuffer_subscription)
    failover.on_receipt &method(:debuffer_frame)
    
    failover.on_failover_connected &method(:replay)
  end
  
  # Adds a frame to a buffer so that it may be replayed if the
  # {OnStomp::Failover::Client failover} client re-connects
  def buffer_frame f, *_
    @buffer_mutex.synchronize do
      # Don't re-buffer frames that are being replayed.
      unless f.header? :'x-onstomp-failover-replay'
        # Create a receipt header, unless the frame already has one.
        f[:receipt] = OnStomp.next_serial unless f.header?(:receipt)
        @buffer << f 
      end
    end
  end
  
  # Records the start of a transaction so that it may be replayed if the
  # {OnStomp::Failover::Client failover} client re-connects
  def buffer_transaction f, *_
    @txs[f[:transaction]] = true
    buffer_frame f
  end
  
  # Removes the recorded transaction from the buffer after it has been
  # written the broker socket so that it will not be replayed when the
  # {OnStomp::Failover::Client failover} client re-connects
  def debuffer_transaction f
    tx = f[:transaction]
    if @txs.delete tx
      @buffer_mutex.synchronize do
        @buffer.reject! { |bf| bf[:transaction] == tx }
      end
    end
  end
  
  # Removes the matching SUBSCRIBE frame from the buffer after the
  # UNSUBSCRIBE has been added to the connection's write buffer
  # so that it will not be replayed when the
  # {OnStomp::Failover::Client failover} client re-connects
  def debuffer_subscription f, *_
    @buffer_mutex.synchronize do
      @buffer.reject! { |bf| bf.command == 'SUBSCRIBE' && bf[:id] == f[:id] }
    end
  end
  
  # Removes frames that neither transactional nor SUBSCRIBEs from the buffer
  # by looking the buffered frames up by their `receipt` header.
  def debuffer_frame r, *_
    orig = @buffer_mutex.synchronize do
      @buffer.detect { |f| f[:receipt] == r[:'receipt-id'] }
    end
    if orig
      # COMMIT and ABORT debuffer the whole transaction sequence
      if ['COMMIT', 'ABORT'].include? orig.command
        debuffer_transaction orig
      # Otherwise, if this isn't part of a transaction, debuffer the
      # particular frame (if it's not a SUBSCRIBE)
      elsif orig.command != 'SUBSCRIBE' && !orig.header?(:transaction)
        @buffer_mutex.synchronize { @buffer.delete orig }
      end
    end
  end
  
  # Called when the {OnStomp::Failover::Client failover} client triggers
  # `on_failover_connected` to start replaying any frames in the buffer.
  def replay fail, client, *_
    replay_frames = @buffer_mutex.synchronize do
      @buffer.select { |f| f[:'x-onstomp-failover-replay'] = '1'; true }
    end
    
    replay_frames.each do |f|
      client.transmit f
    end
  end
end
