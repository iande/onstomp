# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Components
  describe NilProcessor do
    let(:client) { mock('client') }
    let(:processor) { NilProcessor.new client }
    
    describe ".start" do
      it "should return itself" do
        processor.start.should == processor
      end
    end
    describe ".stop" do
      it "should return itself" do
        processor.stop.should == processor
      end
    end
    describe ".join" do
      it "should return itself" do
        processor.join.should == processor
      end
    end
    describe ".running?" do
      it "should never be running" do
        processor.running?.should be_false
        processor.start
        processor.running?.should be_false
      end
    end
  end
end
