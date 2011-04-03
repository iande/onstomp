# -*- encoding: utf-8 -*-
require 'open-uri'

class OnStomp::Components::URI::STOMP
  def open(*args)
    client = OnStomp::Client.new(self, *args)
    client.extend OnStomp::OpenURI::ClientExtensions
    client.auto_destination = self.path
    if block_given?
      begin
        client.connect
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

require 'onstomp/open-uri/message_queue'
require 'onstomp/open-uri/client_extensions'
