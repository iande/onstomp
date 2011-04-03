# -*- encoding: utf-8 -*-
require 'spec_helper'

describe "OnStomp::Client.new with failover", :failover => true do
  describe "monkey patching OnStomp::Client" do
    it "should return a failover client if given an array" do
      OnStomp::Client.new(['stomp:///', 'stomp+ssl:///']).should be_a_kind_of(OnStomp::Failover::Client)
    end
    it "should return a failover client if given a failover: URI" do
      OnStomp::Client.new('failover:(stomp:///,stomp+ssl:///)').should be_a_kind_of(OnStomp::Failover::Client)
    end
    it "should be a regular client otherwise" do
      OnStomp::Client.new('stomp:///').should be_a_kind_of(OnStomp::Client)
    end
  end
end
