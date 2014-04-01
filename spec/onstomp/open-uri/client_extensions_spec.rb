# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::OpenURI
  describe ClientExtensions do
    let(:client) {
      mock('client', :subscribe => true).tap do |m|
        m.extend ClientExtensions
      end
    }
    
    before(:each) do
      client.auto_destination = '/queue/test'
    end
    
    describe "::extended" do
      let(:to_extend) {
        mock("to be extended", :send => 'send', :puts => 'puts',
          :send_with_openuri => 'send_with_openuri')
      }
      it "should alias set up aliases" do
        to_extend.extend ClientExtensions
        to_extend.send_without_openuri.should == 'send'
        to_extend.send.should == 'send_with_openuri'
        to_extend.puts.should == 'send_with_openuri'
      end
    end
    
    describe ".send" do
      it "should use the auto destination if none is given" do
        client.should_receive(:send_without_openuri).with('/queue/test',
          'body of message', :header1 => 'value 1')
        client.send 'body of message', :header1 => 'value 1'
      end
      
      it "should use a destination if one is provided" do
        client.should_receive(:send_without_openuri).with('/topic/other',
          'i have built these walls', :get_by => "you can't")
        client.send '/topic/other', 'i have built these walls',
          :get_by => "you can't"
      end
      it "should raise an error if the auto destination is nil" do
        client.auto_destination = nil
        lambda {
          client.send 'body of message', :header1 => 'value 1'
        }.should raise_error(OnStomp::OpenURI::UnusableDestinationError)
      end
      it "should raise an error if the auto destination is empty" do
        client.auto_destination = ''
        lambda {
          client.send 'body of message', :header1 => 'value 1'
        }.should raise_error(OnStomp::OpenURI::UnusableDestinationError)
      end
      it "should raise an error if the auto destination is '/'" do
        client.auto_destination = '/'
        lambda {
          client.send 'body of message', :header1 => 'value 1'
        }.should raise_error(OnStomp::OpenURI::UnusableDestinationError)
      end
    end
    
    describe ".each" do
      it "should return an enumerator if no block is given" do
        client.each.should be_a_kind_of(Enumerable)
      end
      it "should yield up elements of the message queue" do
        yielded = []
        client.stub(:openuri_message_queue).and_return(['one', 'two', 'three'])
        client.each do |m|
          yielded << m
          break if yielded.size > 2
        end
        yielded.should == ['one', 'two', 'three']
      end
      it "should subscribe to the auto destination only once" do
        client.stub(:openuri_message_queue).and_return(['one', 'two'])
        client.should_receive(:subscribe).with('/queue/test').and_return(true)
        client.each { |m| break }
        client.should_not_receive(:subscribe)
        client.each { |m| break }
      end
      it "should push subscription messages on the message queue" do
        message_queue = mock('queue')
        client.stub(:openuri_message_queue => message_queue)
        client.should_receive(:subscribe).with('/queue/test').and_yield 'me time'
        message_queue.should_receive(:<<).with 'me time'
        message_queue.should_receive(:shift).and_return "tonight it's all right"
        yielded = nil
        client.each do |m|
          yielded = m
          break
        end
        yielded.should == "tonight it's all right"
      end
    end
    
    describe ".first / .take / .gets" do
      before(:each) do
        client.stub(:openuri_message_queue).and_return(['one', 'two',
          'three', 'four'])
      end
      it "should return only one element if no args are given" do
        client.first.should == 'one'
        client.take.should == 'two'
        client.gets.should == 'three'
      end
      it "should return an array if an argument is given" do
        client.gets(1).should == ['one']
        client.take(2).should == ['two', 'three']
      end
    end
  end
end
