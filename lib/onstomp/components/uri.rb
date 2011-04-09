# -*- encoding: utf-8 -*-

# Subclasses of URI::Generic to ease working with Stomp URIs.
module OnStomp::Components::URI
  # A URI class for representing URIs with a 'stomp' scheme.
  class STOMP < ::URI::Generic
    # The default port to use for these kinds of URI objects when none has
    # been specified.
    DEFAULT_PORT = 61613
    # The type of socket to use with these kinds of URI objects.
    # @return [:tcp]
    def onstomp_socket_type; :tcp; end
  end
  
  # A URI class for representing URIs with a `stomp+ssl` scheme.
  class STOMP_SSL < STOMP
    # The default port to use for these kinds of URI objects when none has
    # been specified.
    DEFAULT_PORT = 61612
    # The type of socket to use with these kinds of URI objects.
    # @return [:ssl]
    def onstomp_socket_type; :ssl; end
  end
end

# Add the new URI classes to `URI`'s set of known schemes.
module ::URI
  @@schemes['STOMP'] = OnStomp::Components::URI::STOMP
  @@schemes['STOMP+SSL'] = OnStomp::Components::URI::STOMP_SSL
end