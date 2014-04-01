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
    
    describe ".set? / .present?" do
      it "should be false if the header is not set" do
        headers.set?(:any_old_thing).should be_false
        headers.present?(:any_old_thing).should be_false
      end
      it "should be set? but not present? when set to nil" do
        headers[:nil_valued] = nil
        headers.set?(:nil_valued).should be_true
        headers.present?(:nil_valued).should be_false
      end
      it "should be set? but not present? when set to empty string" do
        headers[:empty_valued] = ''
        headers.set?(:empty_valued).should be_true
        headers.present?(:empty_valued).should be_false
      end
      it "should be set? and present? when set to a non-empty value" do
        headers[:nonempty_valued] = 31011
        headers.set?(:nonempty_valued).should be_true
        headers.present?(:nonempty_valued).should be_true
      end
    end
    
    describe ".append / .all_values" do
      it "should create a new header name if one did not exist" do
        headers.set?(:appended).should be_false
        headers.append('appended', 'value 1')
        headers.set?(:appended).should be_true
        headers.all_values(:appended).should == ['value 1']
      end
      it "should append to existing values" do
        headers[:appended1] = 'me'
        headers.append('appended1', 'me too!')
        headers.append('appended2', 'me also?')
        headers.append(:appended2, 'why not')
        headers.all_values(:appended1).should == ['me', 'me too!']
        headers.all_values('appended2').should == ['me also?', 'why not']
      end
    end
    
    describe ".delete" do
      it "should return nil if the header has not been set" do
        headers.delete(:whatever).should be_nil
      end
      it "should return all values as an array and remove the set header" do
        headers['todelete'] = 5
        headers.append(:todelete, 510)
        headers.delete(:todelete).should == ['5', '510']
        headers.set?(:todelete).should be_false
      end
    end
    
    describe "hash-like access .[] and .[]=" do
      it "should be accessible via strings or symbols" do
        headers['indifferent'] = 'sweet'
        headers[:indifferent].should == 'sweet'
        headers['indifferent'].should == 'sweet'
      end
      
      it "should return nil if the header isn't set" do
        headers[:what_of_it?].should be_nil
        headers['what_of_it?'].should be_nil
      end
      
      it "should return the principle (first assigned) value" do
        headers.append('appended', 'first value')
        headers.append(:'appended', 'second value')
        headers.append('appended', 'last value')
        headers[:appended].should == 'first value'
      end
      
      it "should convert the assigned value to a string" do
        headers['conversion'] = 310831
        headers[:conversion].should == '310831'
        headers[:convert_nil] = nil
        headers['convert_nil'].should == ''
      end
    end
    
    describe ".to_hash" do
      it "should convert itself to a hash of header names and their principle values" do
        headers[:lonely_me] = true
        headers.append('appended', 'first value')
        headers.append(:'appended', 'second value')
        headers.append('appended', 'last value')
        headers.to_hash.should == { :lonely_me => 'true', :appended => 'first value' }
      end
    end
    
    describe ".each" do
      it "should be a kind of enumerable" do
        headers.should be_a_kind_of(Enumerable)
      end
      
      it "should yield an enumerator if called without a block" do
        headers.each.should be_a_kind_of(Enumerable)
      end
      
      it "should yield header names and values as pairs of strings" do
        yielded = []
        headers[:named1] = 'value 1'
        headers[:named2] = 'value 2'
        headers.each { |pair| yielded << pair }
        yielded.should == [ ['named1', 'value 1'], ['named2', 'value 2'] ]
      end
      
      it "should yield repeated headers within the pairs" do
        yielded = []
        headers[:named1] = 'value 1'
        headers[:named2] = 'value 2'
        headers[:named3] = 'value 3'
        headers.append('named2', 'yet another')
        headers.append('named1', 'why not one more?')
        headers.each { |k, v| yielded << [k, v] }
        yielded.should == [
          ['named1', 'value 1'], ['named1', 'why not one more?'],
          ['named2', 'value 2'], ['named2', 'yet another'],
          ['named3', 'value 3']
        ]
      end
    end
  end
end
