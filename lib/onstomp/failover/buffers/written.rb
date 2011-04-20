# -*- encoding: utf-8 -*-

# A buffer that ensures frames are at least written to a
# {OnStomp::Client client}'s {OnStomp::Connections::Base connection} and
# replays the ones that were not when the
# {OnStomp::Failover::Client failover} client reconnects.
class OnStomp::Failover::Buffers::Written < OnStomp::Failover::Buffers::Base
  def initialize failover
    super
    [:send, :commit, :abort, :subscribe].each do |ev|
      failover.__send__(:"before_#{ev}") do |f, *_|
        add_to_buffer f
      end
    end
    # We only want to scrub the transactions if ABORT or COMMIT was
    # at least written fully to the socket.
    [:commit, :abort].each do |ev|
      failover.__send__(:"on_#{ev}") do |f,*_|
        remove_from_transactions f
      end
    end
    failover.before_begin { |f, *_| add_to_transactions f }
    # We can scrub the subscription before UNSUBSCRIBE is fully written
    # because if we replay before UNSUBSCRIBE was sent, we still don't
    # want to be subscribed when we reconnect.
    failover.before_unsubscribe { |f, *_| remove_subscribe_from_buffer f }
    failover.on_send &method(:debuffer_non_transactional_frame)
    failover.on_failover_connected { |f,c,*_| replay_buffer c }
  end

  # Removes a frame that is not part of a transaction from the buffer
  # after it has been written the broker socket so that it will not be
  # replayed when the {OnStomp::Failover::Client failover} client re-connects
  def debuffer_non_transactional_frame f, *_
    unless @txs.key?(f[:transaction])
      @buffer_mutex.synchronize { @buffer.delete f }
    end
  end
end
