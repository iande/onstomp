# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Connections::Serializers
  describe Stomp_1_1 do
    let(:serializer) { Stomp_1_1.new }
    describe "ancestors" do
      it "should be a kind of Stomp_1 serializer" do
        serializer.should be_a_kind_of(OnStomp::Connections::Serializers::Stomp_1)
      end
    end
    
    describe ".frame_to_string" do
      # So tests pass with Ruby 1.8.7, we need to get the headers in order
      let(:frame_without_body) {
        OnStomp::Components::Frame.new('COMMAND').tap do |f|
          f[:header1] = 'value 1'
          f[:header2] = 'value 2'
          f["header\nwith:special \\characters"] = "value:with\\special\ncharacters"
        end
      }
      let(:frame_with_body) {
        OnStomp::Components::Frame.new('COMMAND',{},'body of message').tap do |f|
          f[:header1] = 'value 1'
          f[:header2] = 'value 2'
          f["header\nwith:special \\characters"] = "value:with\\special\ncharacters"
        end
      }
      it "should convert a frame to a string with escaped headers" do
        serializer.frame_to_string(frame_without_body).should ==
          "COMMAND\nheader1:value 1\nheader2:value 2\nheader\\nwith\\cspecial \\\\characters:value\\cwith\\\\special\\ncharacters\n\n\000"
      end
      it "should generate a content-length and content-type" do
        expected_str = if RUBY_VERSION >= '1.9'
          frame_with_body.body = frame_with_body.body.encode('ISO-8859-1')
          "COMMAND\nheader1:value 1\nheader2:value 2\nheader\\nwith\\cspecial \\\\characters:value\\cwith\\\\special\\ncharacters\ncontent-type:text/plain;charset=ISO-8859-1\ncontent-length:15\n\nbody of message\000"
        else
          "COMMAND\nheader1:value 1\nheader2:value 2\nheader\\nwith\\cspecial \\\\characters:value\\cwith\\\\special\\ncharacters\ncontent-length:15\n\nbody of message\000"
        end
        serializer.frame_to_string(frame_with_body).should == expected_str
      end
    end
    
    describe ".split_header" do
      it "should raise a malformed header error if the header line has no ':'" do
        lambda {
          serializer.split_header('header-name')
        }.should raise_error(OnStomp::MalformedHeaderError)
      end
      it "should raise an invalid escape sequence error given a bad escape sequence" do
        lambda {
          serializer.split_header('header-name:header\\rvalue')
        }.should raise_error(OnStomp::InvalidHeaderEscapeSequenceError)
      end
      it "should raise an invalid escape sequence error given an incomplete escape sequence" do
        lambda {
          serializer.split_header('header-name\\:header\\cvalue')
        }.should raise_error(OnStomp::InvalidHeaderEscapeSequenceError)
      end
      it "should return an unescaped header name/value pair" do
        serializer.split_header('header\\cname\\\\is\\nme:value\\\\is\\nthis\\cguy').should == 
          ["header:name\\is\nme", "value\\is\nthis:guy"]
      end
    end
    
    describe ".prepare_parsed_frame" do
      let(:iso8859_frame) {
        OnStomp::Components::Frame.new('COMMAND', {
          :header1 => 'value 1',
          :header2 => 'value 2',
          :'content-length' => '5',
          :'content-type' => 'text/plain;charset=ISO-8859-1',
          "header\nwith:special \\characters" => "value:with\\special\ncharacters"
        }, "h\xEBllo")
      }
      let(:utf8_frame) {
        OnStomp::Components::Frame.new('COMMAND', {
          :header1 => 'value 1',
          :header2 => 'value 2',
          :'content-length' => '6',
          :'content-type' => 'text/plain',
          "header\nwith:special \\characters" => "value:with\\special\ncharacters"
        }, "h\xC3\xABllo")
      }
      before(:each) do
        if RUBY_VERSION > '1.9'
          iso8859_frame.body.force_encoding('ASCII-8BIT')
          utf8_frame.body.force_encoding('ASCII-8BIT')
        end
      end
      it "should force a body encoding on the frame" do
        serializer.prepare_parsed_frame(iso8859_frame)
        serializer.prepare_parsed_frame(utf8_frame)
        iso8859_frame.should have_body_encoding('ISO-8859-1')
        utf8_frame.should have_body_encoding('UTF-8')
      end
    end
  end
end
