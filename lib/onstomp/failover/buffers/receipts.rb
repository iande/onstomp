# -*- encoding: utf-8 -*-

# A buffer that ensures frames are RECEIPTed against a
# {OnStomp::Client client}'s {OnStomp::Connections::Base connection} and
# replays the ones that were not when the
# {OnStomp::Failover::Client failover} client reconnects.
# @todo Quite a lot of this code is shared between Written and Receipts,
#   we'll want to factor the common stuff out.
class OnStomp::Failover::Buffers::Receipts < OnStomp::Failover::Buffers::Base
  def initialize failover
    super
    [:send, :commit, :abort, :subscribe].each do |ev|
      failover.__send__(:"before_#{ev}") do |f, *_|
        add_to_buffer f, {:receipt => OnStomp.next_serial}
      end
    end
    failover.before_begin do |f, *_|
      add_to_transactions f, {:receipt => OnStomp.next_serial}
    end
    # We can scrub the subscription before UNSUBSCRIBE is fully written
    # because if we replay before UNSUBSCRIBE was sent, we still don't
    # want to be subscribed when we reconnect.
    failover.before_unsubscribe do |f, *_|
      remove_subscribe_from_buffer f
    end
    failover.on_receipt { |r, *_| debuffer_frame r }
    failover.on_failover_connected { |f,c,*_| replay_buffer c }
  end
  
  
  # Removes frames that neither transactional nor SUBSCRIBEs from the buffer
  # by looking the buffered frames up by their `receipt` header.
  def debuffer_frame r
    orig = @buffer_mutex.synchronize do
      @buffer.detect { |f| f[:receipt] == r[:'receipt-id'] }
    end
    if orig
      # COMMIT and ABORT debuffer the whole transaction sequence
      if ['COMMIT', 'ABORT'].include? orig.command
        remove_from_transactions orig
      # Otherwise, if this isn't part of a transaction, debuffer the
      # particular frame (if it's not a SUBSCRIBE)
      elsif orig.command != 'SUBSCRIBE' && !orig.header?(:transaction)
        @buffer_mutex.synchronize { @buffer.delete orig }
      end
    end
  end
end
