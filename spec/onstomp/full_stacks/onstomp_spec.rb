# -*- encoding: utf-8 -*-
require 'spec_helper'
require File.expand_path('../test_broker', __FILE__)

describe OnStomp::Client, "full stack test", :fullstack => true do
  let(:broker) {
    TestBroker.new
  }
  before(:each) do
    broker.start
  end
  after(:each) do
    broker.stop
  end
end
