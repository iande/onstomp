# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Failover::Pools
  describe RoundRobin, :failover => true do
    let(:clients) {
      [ '1', '2', '3']
    }
    let(:pool) {
      RoundRobin.new([]).tap do |p|
        p.stub(:clients => clients)
      end
    }
    
    describe ".next_client" do
      it "should return clients in order and cycle" do
        pool.next_client.should == '1'
        pool.next_client.should == '2'
        pool.next_client.should == '3'
        pool.next_client.should == '1'
        pool.next_client.should == '2'
        pool.next_client.should == '3'
        pool.next_client.should == '1'
      end
    end
  end
end
