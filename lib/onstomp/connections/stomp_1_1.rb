# -*- encoding: utf-8 -*-

class OnStomp::Connections::Stomp_1_1 < OnStomp::Connections::Base
  include OnStomp::Connections::Stomp_1
  include OnStomp::Connections::Heartbeating
  attr_reader :serializer
  
  def initialize io, client
    super
    @serializer = OnStomp::Connections::Serializers::Stomp_1_1.new
  end
  
  def configure connected, con_cbs
    super
    configure_heartbeating client.heartbeats, connected.heart_beat
  end
  
  def connected?
    super && pulse?
  end
  
  def ack_frame *args
    create_ack_or_nack 'ACK', args
  end
  
  def nack_frame *args
    create_ack_or_nack 'NACK', args
  end
  
  def heartbeat_frame
    OnStomp::Components::Frame.new
  end
  
  private
  def create_ack_or_nack(command, args)
    headers = args.last.is_a?(Hash) ? args.pop : {}
    m_id = args.shift
    sub_id = args.shift
    if m_id.is_a?(OnStomp::Components::Frame)
      sub_id = m_id[:subscription]
      m_id = m_id[:'message-id']
    end
    create_frame(command, [{:'message-id' => m_id, :subscription => sub_id }, headers]).tap do |f|
      raise ::ArgumentError, 'missing message-id or subscription headers' unless f.headers?(:'message-id', :subscription)
    end
  end
end
