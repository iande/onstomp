# -*- encoding: utf-8 -*-
require 'spec_helper'

describe OnStomp do
  describe ".connect / .open" do
    let(:client) { mock('client') }
    let(:client_uri) { mock('uri') }
    let(:client_options) { mock('options') }
    it "should create a new client and connect it" do
      OnStomp::Client.should_receive(:new).with(client_uri, client_options).and_return(client)
      client.should_receive(:connect)
      OnStomp.open(client_uri, client_options).should == client
    end
  end
end
