# -*- encoding: utf-8 -*-
require 'open-uri'

class OnStomp::Components::URI::STOMP
  def open(*args)
    client = OnStomp::OpenURI::Client.new(self, *args)
    if block_given?
      begin
        yield client
      ensure
        client.disconnect
      end
    end
    client
  end
end

module OnStomp::OpenURI
  class UnusableDestinationError < OnStomp::OnStompError; end
end

require 'onstomp/open-uri/nil_processor'
require 'onstomp/open-uri/client'
