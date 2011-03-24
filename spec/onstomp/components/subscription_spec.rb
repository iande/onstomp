# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Components
  describe Subscription do
    let(:frame) {
      mock('frame')
    }
    let(:callback) {
      mock('callback')
    }
    let(:subscription) {
      Subscription.new frame, callback
    }
    
    describe ".initialize" do
      it "should take a frame and a callback" do
        subscription.frame.should == frame
        subscription.callback.should == callback
      end
    end
    
    describe ".id" do
      it "should pull the id header from its frame" do
        frame.stub(:[]).with(:id).and_return('s-1234')
        subscription.id.should == 's-1234'
      end
    end
    
    describe ".destination" do
      it "should pull the destination header from its frame" do
        frame.stub(:[]).with(:destination).and_return('some.path.to.write')
        subscription.destination.should == 'some.path.to.write'
      end
    end
    
    describe ".call" do
      it "should invoke its callback with the supplied frame" do
        callback.should_receive(:call).with(frame)
        subscription.call(frame)
      end
    end
    
    describe ".include?" do
      it "should return true if the supplied frame's destination matches its destination" do
        subscription.stub(:destination => 'some.path.to.write')
        frame.stub(:[]).with(:destination).and_return('some.path.to.write')
        subscription.should include(frame)
      end
      
      it "should return false if the supplied frame's destination does not match its destination" do
        subscription.stub(:destination => 'some.other.path.to.write')
        frame.stub(:[]).with(:destination).and_return('some.path.to.write')
        subscription.should_not include(frame)
      end
    end
  end
end
