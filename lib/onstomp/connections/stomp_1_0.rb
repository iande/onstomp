# -*- encoding: utf-8 -*-

class OnStomp::Connections::Stomp_1_0 < OnStomp::Connections::Base
  include OnStomp::Connections::Stomp_1
  attr_reader :serializer

  def initialize io, disp
    super
    @serializer = OnStomp::Connections::Serializers::Stomp_1_0.new
  end

  def ack_frame *args
    headers = args.last.is_a?(Hash) ? args.pop : {}
    m_id = args.shift
    m_id = m_id[:'message-id'] if m_id.is_a?(OnStomp::Components::Frame)
    create_frame('ACK', [{:'message-id' => m_id}, headers]).tap do |f|
      raise ArgumentError, 'no message-id to ACK' unless f.header?(:'message-id')
    end
  end
end
