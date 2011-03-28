# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Connections::Serializers
  describe Stomp_1 do
    let(:serializer) {
      mock('serializer').tap do |m|
        m.extend Stomp_1
      end
    }
    describe ".frame_to_bytes" do
      let(:frame) {
        mock('frame')
      }
      it "should call frame_to_string and encode the result to ASCII-8BIT" do
        serializer.stub(:frame_to_string).with(frame).and_return('SERIALIZED FRAME')
        ser = serializer.frame_to_bytes(frame)
        ser.should == 'SERIALIZED FRAME'
        if RUBY_VERSION >= '1.9'
          ser.encoding.name.should == 'ASCII-8BIT'
        end
      end
    end
    
    describe ".frame_to_string_base" do
      let(:frame) {
        OnStomp::Components::Frame.new('COMMAND', {
          :heaDer1 => 'Value 1',
          :headeR2 => 'Value 2',
          'HEADER3' => 'Value 3'
        }, "body of frame")
      }
      it "should treat a frame with no command as a heartbeat" do
        frame.command = nil
        serializer.frame_to_string_base(frame).should == "\n"
      end
      it "should serialize a frame as a string, yielding headers to the supplied block" do
        serializer.frame_to_string_base(frame) do |k,v|
          "#{k.downcase}:#{v.upcase}\n"
        end.should == "COMMAND\nheader1:VALUE 1\nheader2:VALUE 2\nheader3:VALUE 3\ncontent-length:13\n\nbody of frame\000"
      end
    end
    
    describe ".bytes_to_frame" do
      let(:buffer1) {
        [ "COMMAND1\nheader",
          " 1:Test value 1",
          "\nHeader 2:",
          "Test value 2\n",
          "content-leng",
          "th:1",
          "6\n\ntesting this guy",
          "\000\n\nCOMMAND4",
          "\nNext Header: some value \nMore headers:another value\n",
          "\nbody of the frame without content-length\000\nCOMMAND5" ]
      }
      let(:buffer2) {
        [ "\nheader:and its value\n\n\000", "COMMAND6\nheader" ]
      }
      let(:buffer3) {
        [ " for command 6:another value\n\nyet another body\000",
          "\n\nCOMMAND9\nlast Header:last Header ValuE!\n\nthis is a" ]
      }
      let(:buffer4) {
        [ "nother body for yet another " ]
      }
      let(:buffer5) {
        [ "frame" ]
      }
      let(:buffer6) {
        [ "\000" ]
      }
      
      before(:each) do
        serializer.reset_parser
      end
      it "should parse and yield the frames contained in the buffers" do
        serializer.should_receive(:split_header).exactly(8).times.and_return do |str|
          str.split(':')
        end
        serializer.should_receive(:prepare_parsed_frame).exactly(5).times
        yielded1 = []
        yielded2 = []
        yielded3 = []
        yielded4 = []
        yielded5 = []
        yielded6 = []
        serializer.reset_parser
        serializer.bytes_to_frame(buffer1) { |f| yielded1 << f }
        serializer.bytes_to_frame(buffer2) { |f| yielded2 << f }
        serializer.bytes_to_frame(buffer3) { |f| yielded3 << f }
        serializer.bytes_to_frame(buffer4) { |f| yielded4 << f }
        serializer.bytes_to_frame(buffer5) { |f| yielded5 << f }
        serializer.bytes_to_frame(buffer6) { |f| yielded6 << f }
        yielded1.size.should == 5
        yielded2.size.should == 1
        yielded3.size.should == 3
        yielded4.size.should == 0
        yielded5.size.should == 0
        yielded6.size.should == 1
      end
      it "should raise a malformed frame error if the content-length is a lie" do
        serializer.stub(:split_header).and_return do |str|
          str.split(':')
        end
        lambda {
          serializer.bytes_to_frame(["COMMAND\ncontent-length:5\n\nmore than 5\000"])
        }.should raise_error(OnStomp::MalformedFrameError)
      end
    end
  end
end
