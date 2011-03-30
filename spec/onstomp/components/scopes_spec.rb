# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Components
  describe Scopes do
    let(:connection) {
      mock('connection')
    }
    let(:scoper) {
      mock('scoper').tap do |m|
        m.extend Scopes
      end
    }
    
    describe ".with_headers" do
      before(:each) do
        scoper.stub :connection => connection
      end
      it "should create a new Header Scope" do
        scoper.with_headers(:header1 => 'value 1', 'header2' => 'value 2').
          should be_a_header_scope(:header1 => 'value 1',
            'header2' => 'value 2')
      end
      it "should yield the scope to a given block" do
        yielded = nil
        scoper.with_headers :header1 => 'value 1', 'header2' => 'value 2' do |h|
          yielded = h
        end
        yielded.should be_a_header_scope(:header1 => 'value 1',
          'header2' => 'value 2')
      end
    end
    
    describe ".with_receipt" do
      before(:each) do
        scoper.stub :connection => connection
      end
      it "should create a new Receipt Scope" do
        callback = lambda { |r| true }
        scoper.with_receipt(&callback).should be_a_receipt_scope(callback)
      end
    end
    
    describe ".transaction" do
      before(:each) do
        scoper.stub(:connection => OnStomp::Connections::Stomp_1_1.new(
          mock('io'), scoper))
      end
      it "should create a new transaction scope" do
        scoper.transaction('t-1234').should be_a_transaction_scope('t-1234')
      end
      it "should evaluate a given block within the transaction" do
        performed = nil
        scoper.should_receive(:transmit).with(an_onstomp_frame('BEGIN'))
        scoper.should_receive(:transmit).with(an_onstomp_frame('COMMIT'))
        scoper.transaction('t-5678') do |t|
          performed = t
        end
        performed.should be_a_transaction_scope
      end
    end
  end
end
