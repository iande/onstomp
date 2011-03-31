# -*- encoding: utf-8 -*-

module OnStomp::Failover::URI
  class FAILOVER < OnStomp::Components::URI::STOMP
    FAILOVER_OPAQUE_REG = /^\(([^\)]+)\)(?:\?(.*))?/
    
    attr_reader :failover_uris
    def initialize(*args)
      super
      _split_opaque_
    end
    
    private
    def _split_opaque_
      if opaque =~ FAILOVER_OPAQUE_REG
        furis, fquery = $1, $2
        @failover_uris = furis.split(',').map { |u| ::URI.parse(u.strip) }
        self.set_opaque nil
        self.set_path ''
        self.set_query fquery
      else
        raise OnStomp::Failover::InvalidFailoverURIError, self.to_s
      end
    end
  end
end

module ::URI
  @@schemes['FAILOVER'] = OnStomp::Failover::URI::FAILOVER
end
