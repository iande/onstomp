# -*- encoding: utf-8 -*-

# Subclasses of URI::Generic to ease working with Stomp URIs.
module OnStomp::Components::URI
  class STOMP < ::URI::Generic
    DEFAULT_PORT = 61613
    class << self
      def stomper_socket_method; :tcp; end
    end
  end

  class STOMP_SSL < STOMP
    DEFAULT_PORT = 61612
    class << self
      def stomper_socket_method; :ssl; end
    end
  end
end

module ::URI
  @@schemes['STOMP'] = OnStomp::Components::URI::STOMP
  @@schemes['STOMP+SSL'] = OnStomp::Components::URI::STOMP_SSL
end