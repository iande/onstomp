# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Failover
  describe URI, :failover => true do
    describe "parsing failover: URIs" do
      it "should parse the string and the internal URIs" do
        uri = ::URI.parse('failover:(stomp://host.domain.tld,stomp+ssl:///?param=value&param2=value2,stomp://user:pass@other.host.tld)?param=blah&param2=testing')
        uri.query.should == 'param=blah&param2=testing'
        uri.failover_uris.map { |u| u.scheme }.should == ['stomp', 'stomp+ssl', 'stomp']
        uri.failover_uris.map { |u| u.host }.should == ['host.domain.tld', nil, 'other.host.tld']
        uri.failover_uris.map { |u| u.query }.should == [nil, 'param=value&param2=value2', nil]
      end
      it "should raise an error if the failover URI doesn't match regex" do
        lambda {
          ::URI.parse('failover://stomp://host.domain.tld,stomp+ssl://sunday.after.you')
        }.should raise_error(OnStomp::Failover::InvalidFailoverURIError)
      end
    end
  end
end
