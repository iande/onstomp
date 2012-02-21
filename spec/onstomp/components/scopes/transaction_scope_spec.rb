# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Components::Scopes
  describe TransactionScope do
    let(:client) {
      OnStomp::Client.new("stomp:///").tap do |c|
        c.stub(:connection => OnStomp::Connections::Stomp_1_1.new(mock('io'), c))
      end
    }
    let(:scope) {
      TransactionScope.new 't-1234', client
    }

    it "sets up the connection attribute" do
      scope.connection.should == scope
    end
    
    describe ".begin" do
      it "should use the scope's transaction id by default" do
        frame = scope.begin :header1 => 'value 1'
        frame.should have_headers(:header1 => 'value 1',
          :transaction => 't-1234')
      end
      it "should use a supplied transaction ID" do
        frame = scope.begin 't-5678', :header1 => 'value 1'
        frame.should have_headers(:header1 => 'value 1',
          :transaction => 't-5678')
      end
      it "should raise an error if the transaction has been started and not finished" do
        scope.begin :header1 => 'value 1'
        lambda {
          scope.begin
        }.should raise_error(OnStomp::TransactionError)
      end
      it "should not raise an error if the transaction has been finished" do
        scope.begin :header1 => 'value 1'
        scope.commit
        lambda {
          scope.begin
        }.should_not raise_error
      end
      it "should generate a new transaction ID after completing" do
        scope.begin :header1 => 'value 1'
        scope.commit
        next_begin = scope.begin
        next_begin[:transaction].should_not be_empty
        next_begin[:transaction].should_not == 't-1234'
      end
    end
    
    describe ".commit" do
      it "should use the scope's transaction id" do
        scope.begin
        scope.commit('t-5678', :header1 => 'value 1').should have_headers(
          :header1 => 'value 1',
          :transaction => 't-1234'
        )
      end
      it "should raise an error if the transaction has not been started" do
        lambda {
          scope.commit
        }.should raise_error(OnStomp::TransactionError)
      end
    end
    
    describe ".abort" do
      it "should use the scope's transaction id" do
        scope.begin
        scope.abort('t-5678', :header1 => 'value 1').should have_headers(
          :header1 => 'value 1',
          :transaction => 't-1234'
        )
      end
      it "should raise an error if the transaction has not been started" do
        lambda {
          scope.abort
        }.should raise_error(OnStomp::TransactionError)
      end
    end
    
    describe ".send" do
      it "should generate a SEND frame with the transaction header" do
        scope.begin
        scope.send('/queue/test', 'body of message').should have_headers(:transaction => 't-1234')
      end
      it "should work with :puts, too!" do
        scope.begin
        scope.puts('/queue/test', 'body of message').should have_headers(:transaction => 't-1234')
      end
      it "should not include the transaction header if the transaction has not started" do
        scope.send('/queue/test', 'body of message').should_not have_header_named(:transaction)
      end
    end
    
    describe ".ack" do
      it "should generate a SEND frame with the transaction header" do
        scope.begin
        scope.ack('m-1234', 's-1234').should have_headers(:transaction => 't-1234')
      end
      it "should not include the transaction header if the transaction has not started" do
        scope.ack('m-1234', 's-1234').should_not have_header_named(:transaction)
      end
    end
    
    describe ".nack" do
      it "should generate a NACK frame with the transaction header" do
        scope.begin
        scope.nack('m-1234', 's-1234').should have_headers(:transaction => 't-1234')
      end
      it "should not include the transaction header if the transaction has not started" do
        scope.nack('m-1234', 's-1234').should_not have_header_named(:transaction)
      end
    end

    describe "non-transactional frames" do
      it "should not add a transaction header to SUBSCRIBE" do
        scope.begin
        scope.subscribe("/queue/test").should_not have_header_named(:transaction)
      end
      it "should not add a transaction header to UNSUBSCRIBE" do
        scope.begin
        scope.unsubscribe("s-1234").should_not have_header_named(:transaction)
      end
      it "should not add a transaction header to DISCONNECT" do
        scope.begin
        scope.disconnect.should_not have_header_named(:transaction)
      end
      it "should not add a transaction header to heartbeats" do
        scope.begin
        scope.beat.should_not have_header_named(:transaction)
      end
    end
    
    describe ".perform" do
      it "should begin an un-started transaction and commit it when the block completes" do
        client.should_receive(:transmit).with(an_onstomp_frame('BEGIN',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('COMMIT',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('SEND',
          {:destination => '/queue/test', :transaction => 't-1234'},
          'my body'), an_instance_of(Hash)).and_return { |f,*_| f }

        scope.perform { |t| t.send("/queue/test", "my body") }
      end
      it "should not begin an already started transaction" do
        scope.begin
        client.should_receive(:transmit).with(an_onstomp_frame('COMMIT',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('SEND',
          {:destination => '/queue/test', :transaction => 't-1234'},
          'my body'), an_instance_of(Hash)).and_return { |f,*_| f }

        scope.perform { |t| t.send("/queue/test", "my body") }
      end
      it "should not commit an already commited transaction" do
        client.should_receive(:transmit).with(an_onstomp_frame('BEGIN',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('COMMIT',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('SEND',
          {:destination => '/queue/test', :transaction => 't-1234'},
          'my body'), an_instance_of(Hash)).and_return { |f,*_| f }

        scope.perform { |t| t.send("/queue/test", "my body"); t.commit }
      end
      it "should not commit an already aborted transaction" do
        client.should_receive(:transmit).with(an_onstomp_frame('BEGIN',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('ABORT',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('SEND',
          {:destination => '/queue/test', :transaction => 't-1234'},
          'my body'), an_instance_of(Hash)).and_return { |f,*_| f }

        scope.perform { |t| t.send("/queue/test", "my body"); t.abort }
      end
      it "should abort if the block raises an error, and re-raise it" do
        client.should_receive(:transmit).with(an_onstomp_frame('BEGIN',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('ABORT',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('SEND',
          {:destination => '/queue/test', :transaction => 't-1234'},
          'my body'), an_instance_of(Hash)).and_return { |f,*_| f }

        lambda {
          scope.perform { |t|
            t.send("/queue/test", "my body")
            raise ArgumentError
          }
        }.should raise_error(ArgumentError)
      end
      it "should not abort if the block raises an error after being aborted" do
        client.should_receive(:transmit).with(an_onstomp_frame('BEGIN',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('ABORT',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('SEND',
          {:destination => '/queue/test', :transaction => 't-1234'},
          'my body'), an_instance_of(Hash)).and_return { |f,*_| f }

        lambda {
          scope.perform { |t|
            t.send("/queue/test", "my body")
            t.abort
            raise ArgumentError
          }
        }.should raise_error(ArgumentError)
      end
      it "should not abort if the block raises an error after being committed" do
        client.should_receive(:transmit).with(an_onstomp_frame('BEGIN',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('COMMIT',
          :transaction => 't-1234')).and_return { |f| f }
        client.should_receive(:transmit).with(an_onstomp_frame('SEND',
          {:destination => '/queue/test', :transaction => 't-1234'},
          'my body'), an_instance_of(Hash)).and_return { |f,*_| f }

        lambda {
          scope.perform { |t|
            t.send("/queue/test", "my body")
            t.commit
            raise ArgumentError
          }
        }.should raise_error(ArgumentError)
      end
    end
  end
end
