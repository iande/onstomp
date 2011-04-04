# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Components
  describe ThreadedProcessor do
    let(:processor) {
      ThreadedProcessor.new(client)
    }
    let(:client) {
      mock("client", :connection => connection, :connected? => false)
    }
    let(:connection) {
      mock("connection", :io_process => nil)
    }
    
    describe ".start / .stop" do
      it "should start and stop the processor" do
        checked_client = false
        client.stub(:connected?).and_return do
          checked_client = true
          Thread.stop
        end
        processor.start
        Thread.pass until checked_client
        processor.running?.should be_true
        processor.stop
        processor.running?.should be_false
      end
      it "should raise any IOErrors raised in the thread, if the client is alive" do
        client.stub(:connected? => true)
        connection.stub(:io_process) do
          raise IOError
        end
        processor.start
        Thread.pass while processor.running?
        lambda { processor.stop }.should raise_error(IOError)
      end
      it "should raise any SystemCallErrors raised in the thread, if the client is alive" do
        client.stub(:connected? => true)
        connection.stub(:io_process) do
          raise SystemCallError.new('blather', 13)
        end
        processor.start
        Thread.pass while processor.running?
        lambda { processor.stop }.should raise_error(SystemCallError)
      end
      it "should not raise any IOErrors raised in the thread, if the client is dead" do
        client.stub(:connected? => true)
        connection.stub(:io_process) do
          raise IOError
        end
        processor.start
        Thread.pass while processor.running?
        client.stub(:connected? => false)
        lambda { processor.stop }.should_not raise_error
      end
      it "should not raise any SystemCallErrors raised in the thread, if the client is dead" do
        client.stub(:connected? => true)
        connection.stub(:io_process) do
          raise SystemCallError.new('blather', 13)
        end
        processor.start
        Thread.pass while processor.running?
        client.stub(:connected? => false)
        lambda { processor.stop }.should_not raise_error
      end
    end
    
    describe ".prepare_to_close" do
      it "should do nothing special if it is not running" do
        processor.stub(:running? => false)
        processor.prepare_to_close
      end
      it "should stop its worker thread, flush the connection's buffer then restart the thread" do
        # ugg....
        def processor.stopped?
          @run_thread.stop?
        end
        client.stub(:connected? => true)
        processor.start
        connection.should_receive(:flush_write_buffer).and_return do
          processor.stopped?.should be_true
          nil
        end
        processor.prepare_to_close
        processor.stopped?.should be_false
      end
    end
    
    describe ".join" do
      it "should block the current thread until connection is no longer alive" do
        joined_properly = false
        joining = false
        spun_up = false
        client_alive = true
        join_tester = Thread.new do
          Thread.pass until joining
          sleep(0.1)
          client.stub(:connected? => false)
          joined_properly = true
        end
        client.stub(:connected?).and_return do
          spun_up = true
        end
        processor.start
        Thread.pass until spun_up
        joining = true
        processor.join
        joined_properly.should be_true
      end
    end
  end
end
