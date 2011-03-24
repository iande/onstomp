# -*- encoding: utf-8 -*-

module OnStomp::Connections::Stomp_1
  def connect_frame *h
    create_frame 'CONNECT', h
  end
  
  def send_frame d, b, h
    create_frame 'SEND', [h, {:destination => d}], b
  end
  
  def begin_frame tx, h
    create_transaction_frame 'BEGIN', tx, h
  end
  
  def commit_frame tx, h
    create_transaction_frame 'COMMIT', tx, h
  end
  
  def abort_frame tx, h
    create_transaction_frame 'ABORT', tx, h
  end
  
  def disconnect_frame h
    create_frame 'DISCONNECT', [h]
  end
  
  def subscribe_frame d, h
    create_frame 'SUBSCRIBE', [{:id => OnStomp.next_serial}, h, {:destination => d}]
  end
  
  def unsubscribe_frame f, h
    id = f.is_a?(OnStomp::Components::Frame) ? f[:id] : f
    create_frame('UNSUBSCRIBE', [{:id => id}, h]).tap do |f|
      raise ArgumentError, 'subscription ID could not be determined' unless f.header?(:id)
    end
  end
  
  private
  def create_transaction_frame command, tx, headers
    create_frame command, [headers, {:transaction => tx}]
  end
  
  def create_frame command, layered_headers, body=nil
    headers = layered_headers.inject({}) do |final, h|
      h = OnStomp.keys_to_sym(h).delete_if { |k,v| final.key?(k) && (v.nil? || v.empty?) }
      final.merge!(h)
      final
    end
    OnStomp::Components::Frame.new(command, headers, body)
  end
end
