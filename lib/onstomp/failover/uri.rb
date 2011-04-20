# -*- encoding: utf-8 -*-

# Namespace for failover related URI classes.
module OnStomp::Failover::URI
  # A URI class for representing URIs with a 'failover' scheme.
  # We don't need to worry about hooking into Ruby's URI parsing jazz since
  # we have full control over when failover URIs will be created.
  class FAILOVER < OnStomp::Components::URI::STOMP
    # Matches a failover URI string, grouping the list of real URIs and
    # any query parameters for the failover URI.
    FAILOVER_REG = /^failover:(?:\/\/)?\(?([^\)]+)\)?(?:\?(.*))?/
    
    attr_reader :failover_uris
    def initialize uris, query
      @failover_uris = uris
      super 'failover', nil, nil, nil, nil, '', "(#{uris.join(',')})", query, nil
    end
    
    # Converts a failover URI into a string. Ruby's Generic URIs don't seem
    # to allow mixing opaques and queries.
    # @return [String]
    def to_s
      base = "#{scheme}:#{opaque}"
      query.nil? || query.empty? ? base : "#{base}?#{query}"
    end
    
    class << self
      # Parses a failover URI string or an array of URIs into a
      # {OnStomp::Failover::URI::FAILOVER} object. Ruby's URI parser works
      # fine with `failover:(uri1,uri2,..)?params=..` style URIs, but chokes
      # on `failover://uri1,uri2,..` forms. This method gives us a bit more
      # flexibility.
      # @note If you are using the `open-uri` extension with `failover`, you
      #   MUST use the `failover:(uri1,uri2,..)` form because `open-uri`
      #   relies on `URI.parse` to convert strings into `URI` objects.
      # @overload parse(str)
      #   @param [String] str
      #   @return [FAILOVER]
      # @overload parse(uri_arr)
      #   @param [Array<String or URI>] uri_arr
      #   @return [FAILOVER]
      def parse uri_str
        if uri_str =~ FAILOVER_REG
          uris = $1
          query = $2
          self.new uris.split(','), query
        else
          raise OnStomp::Failover::InvalidFailoverURIError, uri_str.inspect
        end
      end
    end
  end
end

module ::URI
  @@schemes['FAILOVER'] = OnStomp::Failover::URI::FAILOVER
end
