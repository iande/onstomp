# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Components
  describe ThreadedProcessor do
    let(:processor) {
      ThreadedProcessor.new(client)
    }
    let(:client) {
      mock("client", :connection => connection, :alive? => false)
    }
    let(:connection) {
      mock("connection", :io_process => nil)
    }
    
    describe ".start / .stop" do
      it "should start and stop the processor" do
        checked_client = false
        processor.start
        client.stub(:alive?).and_return do
          checked_client = true
        end
        processor.running?.should be_true
        Thread.pass until checked_client
        processor.stop
        processor.running?.should be_false
      end
      it "should raise any IOErrors raised in the thread, if the client is alive" do
        client.stub(:alive? => true)
        spun_up = false
        processor.start
        connection.stub(:io_process) do
          spun_up = true
          raise IOError
        end
        Thread.pass until spun_up
        lambda { processor.stop }.should raise_error(IOError)
      end
      it "should raise any SystemCallErrors raised in the thread, if the client is alive" do
        client.stub(:alive? => true)
        spun_up = false
        processor.start
        connection.stub(:io_process) do
          spun_up = true
          raise SystemCallError.new('blather', 13)
        end
        Thread.pass until spun_up
        lambda { processor.stop }.should raise_error(SystemCallError)
      end
      it "should not raise any IOErrors raised in the thread, if the client is dead" do
        client.stub(:alive? => true)
        spun_up = false
        processor.start
        connection.stub(:io_process) do
          spun_up = true
          raise IOError
        end
        Thread.pass until spun_up
        client.stub(:alive? => false)
        lambda { processor.stop }.should_not raise_error
      end
      it "should not raise any SystemCallErrors raised in the thread, if the client is dead" do
        client.stub(:alive? => true)
        spun_up = false
        processor.start
        connection.stub(:io_process) do
          spun_up = true
          raise SystemCallError.new('blather', 13)
        end
        processor.running?.should be_true
        Thread.pass until spun_up
        client.stub(:alive? => false)
        lambda { processor.stop }.should_not raise_error
      end
    end
    
    describe ".join" do
      it "should block the current thread until connection is no longer alive" do
        joined_properly = false
        joining = false
        client_alive = true
        join_tester = Thread.new do
          Thread.pass until joining
          sleep(0.1)
          client.stub(:alive? => false)
          joined_properly = true
        end
        client.stub(:alive? => true)
        processor.start
        joining = true
        processor.join
        joined_properly.should be_true
      end
    end
  end
end
