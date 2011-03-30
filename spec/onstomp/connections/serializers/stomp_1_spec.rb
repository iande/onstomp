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
        OnStomp::Components::Frame.new('COMMAND', {}, 'body of frame').tap do |f|
          f[:heaDer1] = 'Value 1'
          f[:headeR2] = 'Value 2'
          f['HEADER3'] = 'Value 3'
        end
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
      let(:buffer) {
        [ "COMMAND1\nheader", " 1:Test value 1", "\nHeader 2:",
          "Test value 2\n", "content-leng", "th:1",
          "6\n\ntesting \000his guy", "\000\n\nCOMMAND4",
          "\nNext Header: some value \nMore headers:another value\n",
          "\nbody of the frame without content-length\000\nCOMMAND6",
          "\nheader:and its value\n\n\000", "COMMAND7\nheader",
          " for command 7:another value\n\nyet another body\000",
          "\n\nCOMMAND10\nlast Header:last Header ValuE!\n\nthis is a",
          "nother body for yet another ", "frame", "\000" ]
      }
      
      before(:each) do
        serializer.reset_parser
        if RUBY_VERSION >= '1.9'
          buffer.each do |b|
            b.force_encoding('ASCII-8BIT')
          end
        end
      end
      it "should parse and yield the frames contained in the buffers" do
        serializer.should_receive(:split_header).exactly(8).times.and_return do |str|
          str.split(':')
        end
        serializer.should_receive(:prepare_parsed_frame).exactly(5).times
        yielded = []
        serializer.bytes_to_frame(buffer) { |f| yielded << f }
        yielded.size.should == 10
        yielded[0].should be_an_onstomp_frame('COMMAND1', {
          :'header 1' => 'Test value 1', :'Header 2' => 'Test value 2',
          :'content-length' => '16'
        }, "testing \000his guy")
        yielded[1].should be_an_onstomp_frame(nil, {}, nil)
        yielded[2].should be_an_onstomp_frame(nil, {}, nil)
        yielded[3].should be_an_onstomp_frame('COMMAND4', {
          :'Next Header' => ' some value ', :'More headers' => 'another value',
        }, 'body of the frame without content-length')
        yielded[4].should be_an_onstomp_frame(nil, {}, nil)
        # Is this what you really want?
        yielded[5].should be_an_onstomp_frame('COMMAND6', {
          :header => 'and its value' }, '')
        yielded[6].should be_an_onstomp_frame('COMMAND7', {
          :'header for command 7' => 'another value' }, 'yet another body')
        yielded[7].should be_an_onstomp_frame(nil, {}, nil)
        yielded[8].should be_an_onstomp_frame(nil, {}, nil)
        yielded[9].should be_an_onstomp_frame('COMMAND10', {
          :'last Header' => 'last Header ValuE!'
        }, 'this is another body for yet another frame')
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
