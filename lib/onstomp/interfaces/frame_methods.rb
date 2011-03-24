# -*- encoding: utf-8 -*-

module OnStomp::Interfaces::FrameMethods
  def send(dest, body, headers={}, &cb)
    transmit connection.send_frame(dest, body, headers), :receipt => cb
  end
  alias :puts :send

  def subscribe(dest, headers={}, &cb)
    transmit connection.subscribe_frame(dest, headers), :subscribe => cb
  end
  
  def unsubscribe(frame_or_id, headers={})
    transmit connection.unsubscribe_frame(frame_or_id, headers)
  end
  
  def begin(tx_id, headers={})
    transmit connection.begin_frame(tx_id, headers)
  end
  
  def abort(tx_id, headers={})
    transmit connection.abort_frame(tx_id, headers)
  end
  
  def commit(tx_id, headers={})
    transmit connection.commit_frame(tx_id, headers)
  end

  def disconnect(headers={})
    transmit connection.disconnect_frame headers
  end

  def ack(*args)
    transmit connection.ack_frame(*args)
  end

  def nack(*args)
    transmit connection.nack_frame(*args)
  end
  
  def beat
    transmit connection.heartbeat_frame
  end
end
