# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Connections
  describe Base do
    let(:io) {
      mock('io', :close => nil)
    }
    let(:client) {
      mock('client', :dispatch_transmitted => nil,
        :dispatch_received => nil)
    }
    let(:serializer) {
      mock('serializer')
    }
    let(:connection) {
      Base.new(io, client)
    }
    let(:frame) {
      mock('frame')
    }
    
    describe ".method_missing" do
      it "should raise an unsupported command error if the method ends in _frame" do
        lambda { connection.lame_frame }.should raise_error(OnStomp::UnsupportedCommandError)
      end
      
      it "should do the regular jazz for other missing methods" do
        lambda { connection.lame_lame }.should raise_error(NameError)
      end
    end
    
    describe ".configure" do
      
    end
    
    describe ".connected?" do
      it "should be connected if io is not closed" do
        io.stub(:closed? => false)
        connection.should be_connected
        io.stub(:closed? => true)
        connection.should_not be_connected
      end
    end
    
    describe ".close" do
      it "should close the socket if blocking is true" do
        io.should_receive(:close)
        connection.close true
      end
      
      it "should close the socket within single_io_write" do
        io.should_receive :close
        connection.close
        connection.io_process_write
      end
    end
    
    describe ".io_process" do
      it "should invoke one io_process_read and one io_process_write" do
        connection.should_receive :io_process_read
        connection.should_receive :io_process_write
        connection.io_process
      end
    end
    
    describe ".write_frame_nonblock" do
      before(:each) do
        connection.stub(:serializer => serializer)
      end
      it "should serialize the frame and push it to the buffer" do
        serializer.stub(:frame_to_bytes).with(frame).and_return('FRAME_SERIALIZED')
        connection.should_receive(:push_write_buffer).with('FRAME_SERIALIZED', frame)
        connection.write_frame_nonblock frame
      end
    end
    
    describe ".(push|shift|unshift)_write_buffer" do
      it "should not add to the buffer if it's closing" do
        connection.close
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        connection.should_not_receive :io_process_write
        connection.close true
      end
      it "should shift the first element off the write buffer" do
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        connection.push_write_buffer 'FRAME_SERIALIZED2', frame
        connection.shift_write_buffer.should == ['FRAME_SERIALIZED', frame]
      end
      it "should put the data and frame at the beginning of the buffer" do
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        connection.unshift_write_buffer 'FRAME_SERIALIZED2', frame
        connection.shift_write_buffer.should == ['FRAME_SERIALIZED2', frame]
      end
    end
    
    describe ".io_process_write" do
      it "should not write if the buffer is empty" do
        io.should_not_receive :write_nonblock
        connection.io_process_write
      end
      it "should not write if the buffer has something but IO.select returns nil" do
        IO.stub(:select => nil)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_not_receive :write_nonblock
        connection.io_process_write
      end
      it "should write to IO in a non-blocking fashion otherwise" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_return(16)
        client.should_receive(:dispatch_transmitted).with(frame)
        connection.io_process_write
      end
      it "should put back the remaining data" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_return(5)
        connection.should_receive(:unshift_write_buffer).with('_SERIALIZED', frame)
        connection.io_process_write
      end
      it "should put all the data back if EINTR is raised" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(Errno::EINTR)
        connection.should_receive(:unshift_write_buffer).with('FRAME_SERIALIZED', frame)
        connection.io_process_write
      end
      it "should put all the data back if EAGAIN is raised" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(Errno::EAGAIN)
        connection.should_receive(:unshift_write_buffer).with('FRAME_SERIALIZED', frame)
        connection.io_process_write
      end
      it "should put all the data back if EWOULDBLOCK is raised" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(Errno::EWOULDBLOCK)
        connection.should_receive(:unshift_write_buffer).with('FRAME_SERIALIZED', frame)
        connection.io_process_write
      end
      it "should close the connection and re-raise if an EOFError is raised" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(EOFError)
        io.should_receive(:close)
        lambda { connection.io_process_write }.should raise_error(EOFError)
      end
      it "should close the connection and re-raise if an IOError is raised" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(IOError)
        io.should_receive(:close)
        lambda { connection.io_process_write }.should raise_error(IOError)
      end
      it "should close the connection and re-raise if an EOFError is raised" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(SystemCallError.new('msg', 13))
        io.should_receive(:close)
        lambda { connection.io_process_write }.should raise_error(SystemCallError)
      end
      it "should re-raise on any other exception" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(Exception)
        lambda { connection.io_process_write }.should raise_error(Exception)
      end
    end
    describe ".io_process_read" do
      before(:each) do
        connection.stub(:serializer => serializer)
      end
      it "should not read if the connection is not alive" do
        connection.stub(:alive? => false)
        io.should_not_receive :read_nonblock
        connection.io_process_read
      end
      it "should not read if IO.select returns nil" do
        connection.stub(:alive? => true)
        IO.stub(:select => nil)
        io.should_not_receive :read_nonblock
        connection.io_process_read
      end
      it "should read IO in a non-blocking fashion otherwise" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_return('FRAME_SERIALIZED')
        serializer.should_receive(:bytes_to_frame).with(['FRAME_SERIALIZED'])
        connection.io_process_read
      end
      it "should dispatch and yield a frame if the serializer yields one" do
        yielded = nil
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_return('FRAME_SERIALIZED')
        serializer.should_receive(:bytes_to_frame).with(['FRAME_SERIALIZED']).and_yield(frame)
        client.should_receive(:dispatch_received).with(frame)
        connection.io_process_read do |f|
          yielded = f
        end
        yielded.should == frame
      end
      it "should not raise an error if EINTR is raised" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(Errno::EINTR)
        lambda { connection.io_process_read }.should_not raise_error
      end
      it "should put all the data back if EAGAIN is raised" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(Errno::EAGAIN)
        lambda { connection.io_process_read }.should_not raise_error
      end
      it "should put all the data back if EWOULDBLOCK is raised" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(Errno::EWOULDBLOCK)
        lambda { connection.io_process_read }.should_not raise_error
      end
      it "should close the connection and not raise error if an EOFError is raised?" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(EOFError)
        io.should_receive(:close)
        lambda { connection.io_process_read }.should_not raise_error
      end
      it "should close the connection and re-raise if an IOError is raised" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(IOError)
        io.should_receive(:close)
        lambda { connection.io_process_read }.should raise_error(IOError)
      end
      it "should close the connection and re-raise if an EOFError is raised" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(SystemCallError.new('msg', 13))
        io.should_receive(:close)
        lambda { connection.io_process_read }.should raise_error(SystemCallError)
      end
      it "should re-raise on any other exception" do
        connection.stub(:alive? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(Exception)
        lambda { connection.io_process_read }.should raise_error(Exception)
      end
    end
    
    describe ".connect" do
      it "should establish the STOMP connection" do
        
      end
    end
  end
end
