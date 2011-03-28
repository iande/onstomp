# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Components
  describe Frame do
    let(:frame) {
      Frame.new
    }
    
    describe ".initialize" do
      it "should create a frame with no command" do
        Frame.new.should have_command(nil)
      end
      it "should create a frame with the supplied command" do
        Frame.new('MANIAC').should have_command('MANIAC')
      end
      it "should create a rame with the supplied command and headers" do
        Frame.new('MANIAC',
          {:mansion => true, 'edit' => 'meteor'}
        ).should be_an_onstomp_frame('MANIAC',
          {:mansion => 'true', :edit => 'meteor'}, nil)
      end
      it "should create a rame with the supplied command, headers and body" do
        Frame.new('MANIAC',
          {:mansion => true, 'edit' => 'meteor'}, 'Bitcrusher'
        ).should be_an_onstomp_frame('MANIAC',
          {:mansion => 'true', :edit => 'meteor'}, 'Bitcrusher')
      end
    end
    
    describe "hash-like access .[] and .[]=" do
      it "should assign a header in a hash-like style" do
        frame[:maniac] = 'mansion'
        frame.headers[:maniac].should == 'mansion'
      end
      it "should retrieve a header in a hash-like style" do
        frame.headers[:maniac] = 'mansion'
        frame[:maniac].should == 'mansion'
      end
    end
    
    describe ".content_length" do
      it "should convert a content-length header to an integer else return nil" do
        frame[:'content-length'] = '510'
        frame.content_length.should == 510
        frame[:'content-length'] = nil
        frame.content_length.should be_nil
      end
    end
    
    describe ".content_type" do
      it "should return an array of nils if no content-type header is set" do
        frame.content_type.should == [nil, nil, nil]
      end
      it "should return an array of nils if the content-type header is not in the standard form" do
        frame[:'content-type'] = ";charset=UTF-8 text/plain"
        frame.content_type.should == [nil, nil, nil]
      end
      it "should parse a type and subtype" do
        frame[:'content-type'] = 'text/plain; param1=value; param2=value;param3=4'
        frame.content_type.should == ['text', 'plain', nil]
      end
      it "should parse a type, subtype and charset" do
        frame[:'content-type'] = 'application-foo/many.pants&shirts; param1=value;charset=UTF-8; param2=value;param3=4'
        frame.content_type.should == ['application-foo', 'many.pants&shirts', 'UTF-8']
      end
    end
    
    describe ".header?" do
      it "should be false if the header is not set" do
        frame.header?(:blather).should be_false
      end
      it "should be false if the header is nil" do
        frame[:blather] = nil
        frame.header?(:blather).should be_false
      end
      it "should be false if the header is empty" do
        frame[:blather] = ''
        frame.header?(:blather).should be_false
      end
      it "should be true if the header is set and non-empty" do
        frame[:blather] = ' '
        frame.header?(:blather).should be_true
      end
    end
    
    describe ".all_headers?" do
      it "should be false if any header is not set" do
        frame[:blather1] = 'test-set'
        frame[:blather2] = 'test-set'
        frame.all_headers?(:blather1, :blather2, :blather3).should be_false
      end
      it "should be false if any header is nil" do
        frame[:blather1] = 'test-set'
        frame[:blather2] = 'test-set'
        frame[:blather3] = nil
        frame.headers?(:blather1, :blather2, :blather3).should be_false
      end
      it "should be false if any header is empty" do
        frame[:blather1] = 'test-set'
        frame[:blather2] = ''
        frame[:blather3] = 'test-set'
        frame.headers?(:blather1, :blather2, :blather3).should be_false
      end
      it "should be true if all headers are set and non-empty" do
        frame[:blather1] = 'three'
        frame[:blather2] = ' '
        frame[:blather3] = 'test-set'
        frame.all_headers?(:blather1, :blather2, :blather3).should be_true
      end
    end
    
    describe ".heart_beat" do
      it "should return [0,0] if no heart-beat header is set" do
        frame.heart_beat.should == [0,0]
      end
      it "should parse a heart-beat header and return an array of integers" do
        frame[:'heart-beat'] = '310,91'
        frame.heart_beat.should == [310, 91]
      end
      it "should return only non-negative values" do
        frame[:'heart-beat'] = '-310,-91'
        frame.heart_beat.should == [0, 0]
        frame[:'heart-beat'] = '-310,91'
        frame.heart_beat.should == [0, 91]
        frame[:'heart-beat'] = '310,-91'
        frame.heart_beat.should == [310, 0]
      end
    end
    
    describe ".force_content_length" do
      it "should not assign a content-length header if there is no body" do
        frame.force_content_length
        frame.headers.set?(:'content-length').should be_false
      end
      
      it "should set a content-length header to the byte-size of the body" do
        frame.body = 'this is a tëst'
        frame.force_content_length
        frame[:'content-length'].should == '15'
      end
    end
  end
end
