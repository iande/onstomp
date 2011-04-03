# -*- encoding: utf-8 -*-
require 'openuri_spec_helper'

describe "open-uri support" do
  let(:stomp_uri) { ::URI.parse("stomp:///") }
  let(:stomp_ssl_uri) { ::URI.parse("stomp+ssl:///") }
  
  describe "open method on URI" do
    let(:open_uri_client) { mock('open-uri client') }
    
    
    it "should create an open-uri client" do
      OnStomp::OpenURI.should_receive(:new).with(stomp_uri,
        :versions => ['1.1','1.0']).and_return(open_uri_client)
      stomp_uri.open({:versions => ['1.1', '1.0']}).should == open_uri_client
    end
    
    it "should yield then disconnect if a block is given" do
      OnStomp::OpenURI.stub(:new => open_uri_client)
      open_uri_client.should_receive(:puts).with('hello world')
      open_uri_client.should_receive(:disconnect)
      stomp_ssl_uri.open do |c|
        c.puts "hello world"
      end
    end
    
    it "should yield then disconnect even if block raises an exception" do
      OnStomp::OpenURI.stub(:new => open_uri_client)
      open_uri_client.should_receive(:disconnect)
      lambda {
        stomp_ssl_uri.open do |c|
          raise "Test Failure"
        end
      }.should raise_error('Test Failure')
    end
  end
end
