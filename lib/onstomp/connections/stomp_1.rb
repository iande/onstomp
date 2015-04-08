# -*- encoding: utf-8 -*-

# Connection behavior common to both STOMP 1.0 and STOMP 1.1 connections
module OnStomp::Connections::Stomp_1
  # Creates a CONNECT frame
  # @return [OnStomp::Components::Frame] CONNECT frame
  def connect_frame *h
    create_frame 'CONNECT', h
  end
  
  # Creates a SEND frame
  # @return [OnStomp::Components::Frame] SEND frame
  def send_frame d, b, h
    create_frame 'SEND', [h, {:destination => d}], b
  end
  
  # Creates a BEGIN frame
  # @return [OnStomp::Components::Frame] BEGIN frame
  def begin_frame tx, h
    create_transaction_frame 'BEGIN', tx, h
  end
  
  # Creates a COMMIT frame
  # @return [OnStomp::Components::Frame] COMMIT frame
  def commit_frame tx, h
    create_transaction_frame 'COMMIT', tx, h
  end
  
  # Creates an ABORT frame
  # @return [OnStomp::Components::Frame] ABORT frame
  def abort_frame tx, h
    create_transaction_frame 'ABORT', tx, h
  end
  
  # Creates a DISCONNECT frame
  # @return [OnStomp::Components::Frame] DISCONNECT frame
  def disconnect_frame h
    create_frame 'DISCONNECT', [h]
  end
  
  # Creates an UNSUBSCRIBE frame
  # @return [OnStomp::Components::Frame] UNSUBSCRIBE frame
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
      h = OnStomp.keys_to_sym(h).delete_if { |k,v| v.nil? || v.empty? }
      final.merge!(h)
      final
    end
    OnStomp::Components::Frame.new(command, headers, body)
  end
end
