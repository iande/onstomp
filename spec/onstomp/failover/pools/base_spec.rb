# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Failover::Pools
  describe Base, :failover => true do
    let(:clients) { mock('clients') }
    let(:pool) {
      Base.new([]).tap do |p|
        p.stub(:clients => clients)
      end
    }

    describe ".initialize" do
      it "should create a new Client for each URI" do
        OnStomp::Client.should_receive(:new).with('1', { option: true }).and_return('c 1')
        OnStomp::Client.should_receive(:new).with('2', { option: true }).and_return('c 2')
        OnStomp::Client.should_receive(:new).with('3', { option: true }).and_return('c 3')
        new_pool = Base.new ['1', '2', '3'], { option: true }
        new_pool.clients.should =~ ['c 1', 'c 2', 'c 3']
      end
    end
    
    describe ".shuffle!" do
      it "should shuffle the clients" do
        clients.should_receive(:shuffle!)
        pool.shuffle!
      end
    end
    
    describe ".next_client" do
      it "should raise an error because it's up to subclasses to implement this warlock" do
        lambda {
          pool.next_client
        }.should raise_error
      end
    end
    
    describe ".each" do
      it "should raise an error if no block is given (not sure why, honestly)" do
        # I think in the past, this method was synchronized, and that's why
        # I raise an error, but it may not be necessary anymore
        lambda {
          pool.each
        }.should raise_error
      end
      it "should evaluate the block against the clients" do
        clients.should_receive(:each).and_yield('c1')
        yielded = []
        pool.each { |c| yielded << c }
        yielded.should == ['c1']
      end
    end
  end
end
