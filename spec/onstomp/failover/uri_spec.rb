# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Failover
  describe URI, :failover => true do
    describe "parsing failover: URIs" do
      def parse_failover_uri str
        OnStomp::Failover::URI::FAILOVER.parse str
      end
      
      it "should parse failover:(uri1,uri2...)?failoverParam1=..." do
        uri = parse_failover_uri 'failover:(stomp://host.domain.tld,stomp+ssl:///?param=value&param2=value2,stomp://user:pass@other.host.tld)?param=blah&param2=testing'
        uri.query.should == 'param=blah&param2=testing'
        uri.failover_uris.map { |u| u.scheme }.should == ['stomp', 'stomp+ssl', 'stomp']
        uri.failover_uris.map { |u| u.host }.should == ['host.domain.tld', nil, 'other.host.tld']
        uri.failover_uris.map { |u| u.query }.should == [nil, 'param=value&param2=value2', nil]
        uri.to_s.should == "failover:(stomp://host.domain.tld,stomp+ssl:///?param=value&param2=value2,stomp://user:pass@other.host.tld)?param=blah&param2=testing"
      end
      it "should parse failover://(uri1,uri2...)?failoverParam1=..." do
        uri = parse_failover_uri 'failover://(stomp://host.domain.tld,stomp+ssl:///?param=value&param2=value2,stomp://user:pass@other.host.tld)?param=blah&param2=testing'
        uri.query.should == 'param=blah&param2=testing'
        uri.failover_uris.map { |u| u.scheme }.should == ['stomp', 'stomp+ssl', 'stomp']
        uri.failover_uris.map { |u| u.host }.should == ['host.domain.tld', nil, 'other.host.tld']
        uri.failover_uris.map { |u| u.query }.should == [nil, 'param=value&param2=value2', nil]
        uri.to_s.should == "failover:(stomp://host.domain.tld,stomp+ssl:///?param=value&param2=value2,stomp://user:pass@other.host.tld)?param=blah&param2=testing"
      end
      it "should parse failover://uri1,uri2,..." do
        uri = parse_failover_uri 'failover://stomp://host.domain.tld,stomp+ssl:///?param=value&param2=value2,stomp://user:pass@other.host.tld'
        uri.query.should be_nil
        uri.failover_uris.map { |u| u.scheme }.should == ['stomp', 'stomp+ssl', 'stomp']
        uri.failover_uris.map { |u| u.host }.should == ['host.domain.tld', nil, 'other.host.tld']
        uri.failover_uris.map { |u| u.query }.should == [nil, 'param=value&param2=value2', nil]
        uri.to_s.should == "failover:(stomp://host.domain.tld,stomp+ssl:///?param=value&param2=value2,stomp://user:pass@other.host.tld)"
      end
      it "should parse an array of failover URIs" do
        uris = [ "stomp://host.domain.tld",
          ::URI.parse("stomp://user:pass@other.host.tld"),
          "stomp+ssl:///?param=value&param2=value2"]
        uri = parse_failover_uri uris
        uri.query.should be_nil
        uri.failover_uris.map { |u| u.scheme }.should == ['stomp', 'stomp', 'stomp+ssl']
        uri.failover_uris.map { |u| u.host }.should == ['host.domain.tld', 'other.host.tld', nil]
        uri.failover_uris.map { |u| u.query }.should == [nil, nil, 'param=value&param2=value2']
        uri.to_s.should == "failover:(stomp://host.domain.tld,stomp://user:pass@other.host.tld,stomp+ssl:///?param=value&param2=value2)"
      end
      it "should raise an error if it doesn't match the regex and isn't an array" do
        lambda {
          # The regex is pretty lax...
          parse_failover_uri "failover:"
        }.should raise_error(OnStomp::Failover::InvalidFailoverURIError)
      end
    end
  end
end
