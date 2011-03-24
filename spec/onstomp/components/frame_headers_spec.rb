# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Components
  describe FrameHeaders do
    let(:headers) {
      FrameHeaders.new
    }
    
    describe ".initialize" do
      it "should create an empty set of headers" do
        FrameHeaders.new.names.should == []
      end
      it "should create headers initialized by a hash" do
        head = FrameHeaders.new({:one => 'one', 'two' => 2})
        head[:one].should == 'one'
        head[:two].should == '2'
      end
    end
    
    describe ".merge!" do
      it "should overwrite existing headers and create new ones" do
        headers[:header1] = 'some value'
        headers['header2'] = 43
        headers.merge!( :header2 => 'new value', 'header3' => 'new header')
        headers.should have_headers(:header1 => 'some value', :header2 => 'new value', :header3 => 'new header')
      end
    end
    
    describe ".reverse_merge!" do
      it "should not overwrite existing headers but create new ones" do
        headers[:header1] = 'some value'
        headers['header2'] = 43
        headers.reverse_merge!( :header2 => 'new value', 'header3' => 'new header')
        headers.should have_headers(:header1 => 'some value', :header2 => '43', :header3 => 'new header')
      end
    end
  end
end
