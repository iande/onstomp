# -*- encoding: utf-8 -*-

module OnStomp::Connections::Heartbeating
  attr_reader :heartbeating
  
  def configure_heartbeating client_beats, broker_beats
    c_x, c_y = client_beats
    s_x, s_y = broker_beats
    @heartbeating = [ (c_x == 0||s_y == 0 ? 0 : [c_x,s_y].max), 
      (c_y == 0||s_x == 0 ? 0 : [c_y,s_x].max) ]
  end
  
  def pulse?
    client_pulse? && broker_pulse?
  end
  
  def heartbeat_client_limit
    unless defined?(@heartbeat_client_limit)
      @heartbeat_client_limit = heartbeating[0] > 0 ? (1.1 * heartbeating[0]) : 0
    end
    @heartbeat_client_limit
  end
  
  def heartbeat_broker_limit
    unless defined?(@heartbeat_broker_limit)
      @heartbeat_broker_limit = heartbeating[1] > 0 ? (1.1 * heartbeating[1]) : 0
    end
    @heartbeat_broker_limit
  end
  
  def duration_since_transmitted
    last_transmitted_at && ((Time.now - last_transmitted_at)*1000).to_i
  end
  
  def duration_since_received
    last_received_at && ((Time.now - last_received_at)*1000).to_i
  end

  def client_pulse?
    heartbeat_client_limit == 0 || duration_since_transmitted <= heartbeat_client_limit
  end

  def broker_pulse?
    heartbeat_broker_limit == 0 || duration_since_received <= heartbeat_broker_limit
  end
end
