# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Interfaces
  describe SubscriptionManager do
    let(:client) {
      mock('client').tap do |m|
        m.extend ClientEvents
        m.extend SubscriptionManager
      end
    }
    let(:message_frame) {
      OnStomp::Components::Frame.new('MESSAGE', :subscription => 's-1234',
        :destination => '/queue/test')
    }
    let(:subscribe_frame) {
      OnStomp::Components::Frame.new('SUBSCRIBE', :id => 's-1234',
        :destination => '/queue/test')
    }
    let(:unsubscribe_frame) {
      OnStomp::Components::Frame.new('UNSUBSCRIBE', :id => 's-1234')
    }
    let(:subscribed_frames) { [] }
    let(:callback) {
      lambda { |m| subscribed_frames << m }
    }
    
    before(:each) do
      client.__send__(:configure_subscription_management)
    end
    after(:each) do
      client.__send__(:clear_subscriptions)
    end
    
    describe "adding subscription callbacks" do
      it "should add a callback and invoke it upon receiving matching MESSAGE" do
        client.__send__ :add_subscription, subscribe_frame, callback
        client.subscriptions.map { |s| [s.id, s.callback] }.should ==
          [ ['s-1234', callback] ]
        client.trigger_after_receiving message_frame
        client.trigger_after_receiving message_frame
        subscribed_frames.should == [message_frame, message_frame]
      end
      it "should invoke the callback if there is no subscription header but destinations match" do
        message_frame.headers.delete :subscription
        client.__send__ :add_subscription, subscribe_frame, callback
        client.trigger_after_receiving message_frame
        client.trigger_after_receiving message_frame
        subscribed_frames.should == [message_frame, message_frame]
      end
    end
    
    describe "unsubscribing" do
      it "should not invoke the callback after UNSUBSCRIBE has been processed" do
        client.__send__ :add_subscription, subscribe_frame, callback
        client.trigger_after_receiving message_frame
        client.trigger_after_receiving unsubscribe_frame
        client.trigger_after_receiving message_frame
        subscribed_frames.should == [message_frame]
        client.subscriptions.should be_empty
      end
    end
  end
end
