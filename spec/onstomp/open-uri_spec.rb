# -*- encoding: utf-8 -*-
require 'spec_helper'

describe "open-uri support", :openuri => true do
  let(:stomp_uri) { ::URI.parse("stomp://host.domain.tld/queue/super-test") }
  let(:stomp_ssl_uri) { ::URI.parse("stomp+ssl://host.domain.tld/queue/super-test") }
  let(:client) {
    mock('client',
      :auto_destination= => nil,
      :extend => nil)
  }
  
  before(:each) do
    OnStomp::Client.stub(:new => client)
  end
  
  it "should create an open-uri client" do
    OnStomp::Client.should_receive(:new).with(stomp_uri,
      :versions => ['1.1','1.0']).and_return(client)
    client.should_receive(:extend).with(OnStomp::OpenURI::ClientExtensions)
    client.should_receive(:auto_destination=).with(stomp_uri.path)
    stomp_uri.open({:versions => ['1.1', '1.0']}).should == client
  end
  
  it "should yield then disconnect if a block is given" do
    client.should_receive(:connect)
    client.should_receive(:puts).with('hello world')
    client.should_receive(:disconnect)
    stomp_ssl_uri.open do |c|
      c.puts "hello world"
    end
  end
  
  it "should yield then disconnect even if block raises an exception" do
    client.should_receive(:connect)
    client.should_receive(:disconnect)
    lambda {
      stomp_ssl_uri.open do |c|
        raise "Test Failure"
      end
    }.should raise_error('Test Failure')
  end
end
