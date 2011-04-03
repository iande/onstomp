# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::OpenURI
  describe MessageQueue do
    let(:queue) {
      MessageQueue.new
    }
    
    describe "adding and removing items" do
      it "should put something onto the queue" do
        queue.push 'one'
        queue << 'two'
        queue.shift.should == 'one'
        queue.shift.should == 'two'
      end
    end
    
    describe ".shift" do
      it "should block until something is pushed" do
        Thread.new do
          sleep 0.1
          queue << 'hello world'
        end
        queue.shift.should == 'hello world'
      end
    end
  end
end
