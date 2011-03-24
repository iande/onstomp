# -*- encoding: utf-8 -*-

# Subclasses of URI::Generic to ease working with Stomp URIs.
module OnStomp::Components::URI
  class STOMP < ::URI::Generic
    DEFAULT_PORT = 61613
    def onstomp_socket_type; :tcp; end
  end

  class STOMP_SSL < STOMP
    DEFAULT_PORT = 61612
    def onstomp_socket_type; :ssl; end
  end
end

module ::URI
  @@schemes['STOMP'] = OnStomp::Components::URI::STOMP
  @@schemes['STOMP+SSL'] = OnStomp::Components::URI::STOMP_SSL
end