# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Connections
  describe Base do
    let(:io) {
      mock('io', :close => nil, :read_nonblock => nil, :write_nonblock => nil)
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

    describe "timeouts" do
      it "defaults write timeout to nil" do
        connection.write_timeout.should be_nil
      end

      it "defaults read timeout to 120 seconds" do
        connection.read_timeout.should == 120
      end
    end
    
    describe ".method_missing" do
      it "should raise an unsupported command error if the method ends in _frame" do
        lambda { connection.lame_frame }.should raise_error(OnStomp::UnsupportedCommandError)
      end
      
      it "should do the regular jazz for other missing methods" do
        lambda { connection.lame_lame }.should raise_error(NameError)
      end
    end

    describe ".connected?" do
      it "should be connected if io is not closed" do
        io.stub(:closed? => false)
        connection.should be_connected
        io.stub(:closed? => true)
        connection.should_not be_connected
      end
    end
    
    describe ".duration_since_transmitted" do
      it "should be nil if last_transmitted_at is nil" do
        connection.stub(:last_transmitted_at => nil)
        connection.duration_since_transmitted.should be_nil
      end
      it "should be the difference between now and the last_transmitted_at in milliseconds" do
        Time.stub(:now => 10)
        connection.stub(:last_transmitted_at => 8.5)
        # Be careful, floating point will give you problems
        connection.duration_since_transmitted.should == 1500.0
      end
    end
    
    describe ".duration_since_received" do
      it "should be nil if last_received_at is nil" do
        connection.stub(:last_received_at => nil)
        connection.duration_since_received.should be_nil
      end
      it "should be the difference between now and the last_received_at in milliseconds" do
        Time.stub(:now => 10)
        connection.stub(:last_received_at => 6)
        connection.duration_since_received.should == 4000.0
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
    
    describe ".flush_write_buffer" do
      it "should run until the buffer is empty" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).exactly(6).times.and_return do |d|
          8
        end
        connection.flush_write_buffer
        connection.shift_write_buffer.should be_nil
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
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_return(16)
        client.should_receive(:dispatch_transmitted).with(frame)
        connection.io_process_write
      end
      it "should put back the remaining data" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_return(5)
        connection.should_receive(:unshift_write_buffer).with('_SERIALIZED', frame)
        connection.io_process_write
      end
      it "should put all the data back if EINTR is raised" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(Errno::EINTR)
        connection.should_receive(:unshift_write_buffer).with('FRAME_SERIALIZED', frame)
        connection.io_process_write
      end
      it "should put all the data back if EAGAIN is raised" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(Errno::EAGAIN)
        connection.should_receive(:unshift_write_buffer).with('FRAME_SERIALIZED', frame)
        connection.io_process_write
      end
      it "should put all the data back if EWOULDBLOCK is raised" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(Errno::EWOULDBLOCK)
        connection.should_receive(:unshift_write_buffer).with('FRAME_SERIALIZED', frame)
        connection.io_process_write
      end
      it "should close the connection and re-raise if an EOFError is raised" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(EOFError)
        io.should_receive(:close)
        lambda { connection.io_process_write }.should raise_error(EOFError)
      end
      it "should close the connection and re-raise if an IOError is raised" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(IOError)
        io.should_receive(:close)
        lambda { connection.io_process_write }.should raise_error(IOError)
      end
      it "should close the connection and re-raise if an EOFError is raised" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(SystemCallError.new('msg', 13))
        io.should_receive(:close)
        lambda { connection.io_process_write }.should raise_error(SystemCallError)
      end
      it "should re-raise on any other exception" do
        triggered = false
        connection.on_terminated { triggered = true }
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        io.should_receive(:close)
        io.should_receive(:write_nonblock).with('FRAME_SERIALIZED').and_raise(Exception)
        lambda { connection.io_process_write }.should raise_error(Exception)
        triggered.should be_true
      end
      it "should trigger a blocked close if the write timeout is exceeded" do
        triggered = false
        connection.on_blocked { triggered = true }
        connection.write_timeout = 10
        Time.stub(:now => 31)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        Time.stub(:now => 77)
        IO.stub(:select => false)
        io.should_receive(:close)
        connection.io_process_write
        triggered.should be_true
      end
    end
    describe ".io_process_read" do
      before(:each) do
        connection.stub(:serializer => serializer)
      end
      it "should not read if the connection is not alive" do
        connection.stub(:connected? => false)
        io.should_not_receive :read_nonblock
        connection.io_process_read
      end
      it "should not read if IO.select returns nil" do
        connection.stub(:connected? => true)
        IO.stub(:select => nil)
        io.should_not_receive :read_nonblock
        connection.io_process_read
      end
      it "should read IO in a non-blocking fashion otherwise" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_return('FRAME_SERIALIZED')
        serializer.should_receive(:bytes_to_frame).with(['FRAME_SERIALIZED'])
        connection.io_process_read
      end
      it "should dispatch and yield a frame if the serializer yields one" do
        yielded = nil
        connection.stub(:connected? => true)
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
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(Errno::EINTR)
        lambda { connection.io_process_read }.should_not raise_error
      end
      it "should put all the data back if EAGAIN is raised" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(Errno::EAGAIN)
        lambda { connection.io_process_read }.should_not raise_error
      end
      it "should put all the data back if EWOULDBLOCK is raised" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(Errno::EWOULDBLOCK)
        lambda { connection.io_process_read }.should_not raise_error
      end
      it "closes the connection and re-raises EOFError when connecting" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(EOFError)
        io.should_receive(:close)
        lambda { connection.io_process_read(true) }.should raise_error(EOFError)
      end
      it "closes the connection without re-raising EOFError when not connecting" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(EOFError)
        io.should_receive(:close)
        lambda { connection.io_process_read }.should_not raise_error
      end
      it "should close the connection and re-raise if an IOError is raised" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(IOError)
        io.should_receive(:close)
        lambda { connection.io_process_read }.should raise_error(IOError)
      end
      it "should close the connection and re-raise if an SystemCallError is raised" do
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(SystemCallError.new('msg', 13))
        io.should_receive(:close)
        lambda { connection.io_process_read }.should raise_error(SystemCallError)
      end
      it "should re-raise on any other exception" do
        triggered = false
        connection.on_terminated { triggered = true }
        connection.stub(:connected? => true)
        IO.stub(:select => true)
        io.should_receive(:close)
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ).and_raise(Exception)
        lambda { connection.io_process_read }.should raise_error(Exception)
        triggered.should be_true
      end
      it "triggers a blocked close and raises ConnectionTimeoutError when connecting" do
        triggered = false
        connection.on_blocked { triggered = true }
        connection.read_timeout = 0.5
        IO.stub(:select => false)
        connection.stub(:connected? => true)
        io.should_receive(:close)
        connection.__send__(:update_last_received)
        lambda do
          connection.io_process_read(true) while true
        end.should raise_error(OnStomp::ConnectionTimeoutError)
        triggered.should be_true
      end
    end
    
    describe "read helpers" do
      it "should not be ready for read if not connected" do
        IO.stub(:select => true)
        connection.stub(:connected? => false)
        connection.__send__(:ready_for_read?).should be_false
      end
      it "should not be ready for read if IO.select is nil" do
        IO.stub(:select => nil)
        connection.stub(:connected? => true)
        connection.__send__(:ready_for_read?).should be_false
      end
      it "should be ready for read if connected and selectable" do
        IO.stub(:select => true)
        connection.stub(:connected? => true)
        connection.__send__(:ready_for_read?).should be_true
      end
      it "should close and trigger terminated event if error is raised" do
        triggered = false
        connection.on_terminated { triggered = true }
        IO.stub(:select).and_raise(IOError)
        connection.stub(:connected? => true)
        lambda {
          connection.__send__(:ready_for_read?)
        }.should raise_error(IOError)
        triggered.should be_true
      end
      it "should not exceed the timeout if no timeout is set" do
        connection.read_timeout = nil
        connection.__send__(:read_timeout_exceeded?).should be_false
      end
      it "should not exceed the timeout if duration is less than timeout" do
        connection.read_timeout = 10
        connection.stub(:duration_since_received => 9000.0)
        connection.__send__(:read_timeout_exceeded?).should be_false
      end
      it "should not exceed the timeout if duration is equal to timeout" do
        connection.read_timeout = 10
        connection.stub(:duration_since_received => 10000.0)
        connection.__send__(:read_timeout_exceeded?).should be_false
      end
      it "should exceed the timeout if duration is greater than timeout" do
        connection.read_timeout = 10
        connection.stub(:duration_since_received => 10000.1)
        connection.__send__(:read_timeout_exceeded?).should be_true
      end
    end
    
    describe "write helpers" do
      it "should not be ready for write if buffer is empty" do
        IO.stub(:select => true)
        connection.__send__(:ready_for_write?).should be_false
      end
      it "should not be ready for write if IO.select is nil" do
        IO.stub(:select => nil)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        connection.__send__(:ready_for_write?).should be_false
      end
      it "should be ready for write if there's buffer data and selectable" do
        IO.stub(:select => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        connection.__send__(:ready_for_write?).should be_true
      end
      it "should close and trigger terminated event if error is raised" do
        triggered = false
        connection.on_terminated { triggered = true }
        IO.stub(:select).and_raise(IOError)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        lambda {
          connection.__send__(:ready_for_write?)
        }.should raise_error(IOError)
        triggered.should be_true
      end
      it "should not exceed the timeout if no timeout is set" do
        connection.write_timeout = nil
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        connection.__send__(:write_timeout_exceeded?).should be_false
      end
      it "should not exceed the timeout if duration is less than timeout" do
        connection.write_timeout = 10
        Time.stub(:now => 59)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        Time.stub(:now => 61)
        connection.__send__(:write_timeout_exceeded?).should be_false
      end
      it "should not exceed the timeout if duration is equal to timeout" do
        connection.write_timeout = 10
        Time.stub(:now => 59)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        Time.stub(:now => 69)
        connection.__send__(:write_timeout_exceeded?).should be_false
      end
      it "should not exceed the timeout if the duration is greater but there's no buffered data" do
        connection.write_timeout = 1
        connection.stub(:duration_since_transmitted => 5000.0)
        connection.__send__(:write_timeout_exceeded?).should be_false
      end
      it "should exceed the timeout if buffered and duration is greater than timeout" do
        Time.stub(:now => 59)
        connection.write_timeout = 10
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        # This proves that not all calls to push_write_buffer reset the clock.
        Time.stub(:now => 70)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        connection.__send__(:write_timeout_exceeded?).should be_true
      end
    end
    
    describe ".connect" do
      let(:headers) { [] }
      let(:connect_frame) {
        OnStomp::Components::Frame.new('CONNECT')
      }
      let(:connected_frame) {
        OnStomp::Components::Frame.new('CONNECTED')
      }
      
      it "should raise an error if the first frame read is not CONNECTED" do
        connection.should_receive(:connect_frame).and_return(connect_frame)
        connection.should_receive(:write_frame_nonblock).with(connect_frame)
        connection.should_receive(:io_process_write).and_yield(connect_frame)
        connection.should_receive(:io_process_read).with(true).and_yield(connected_frame)
        connected_frame.command = 'NOT CONNECTED'
        lambda { connection.connect(client, *headers) }.should raise_error(OnStomp::ConnectFailedError)
      end
      it "should raise an error if the CONNECTED frame specifies an unsolicited version" do
        connection.should_receive(:connect_frame).and_return(connect_frame)
        connection.should_receive(:write_frame_nonblock).with(connect_frame)
        connection.should_receive(:io_process_write).and_yield(connect_frame)
        connection.should_receive(:io_process_read).with(true).and_yield(connected_frame)
        connected_frame[:version] = '1.9'
        client.stub(:versions => [ '1.0', '1.1' ])
        lambda { connection.connect(client, *headers) }.should raise_error(OnStomp::UnsupportedProtocolVersionError)
      end
      it "should assume version 1.0 if no version header is set" do
        connection.should_receive(:connect_frame).and_return(connect_frame)
        connection.should_receive(:write_frame_nonblock).with(connect_frame)
        connection.should_receive(:io_process_write).and_yield(connect_frame)
        connection.should_receive(:io_process_read).with(true).and_yield(connected_frame)
        client.stub(:versions => [ '1.0', '1.1' ])
        connection.connect(client, *headers).should == ['1.0', connected_frame]
      end
      it "should return the CONNECTED version header if it's included" do
        connection.should_receive(:connect_frame).and_return(connect_frame)
        connection.should_receive(:write_frame_nonblock).with(connect_frame)
        connection.should_receive(:io_process_write).and_yield(connect_frame)
        connection.should_receive(:io_process_read).with(true).and_yield(connected_frame)
        connected_frame[:version] = '2.3'
        client.stub(:versions => [ '1.0', '2.3' ])
        connection.connect(client, *headers).should == ['2.3', connected_frame]
      end
      
      it "should trigger :on_died once, if the connection was up but is no longer connected" do
        connection.stub(:connect_frame => connect_frame,
          :write_frame_nonblock => connect_frame)
        client.stub(:versions => ['1.0', '1.1'])
        connection.stub(:io_process_write).and_yield(connect_frame)
        connection.stub(:io_process_read).with(true).and_yield(connected_frame)
        triggered = 0
        connection.on_died { |cl, cn| triggered += 1 }
        connection.connect client
        connection.stub(:io_process_write => nil, :io_process_read => nil)
        connection.stub(:connected? => false)
        connection.io_process
        connection.io_process
        triggered.should == 1
      end

      it "re-raises an error raised while writing during connect" do
        io.stub(:closed? => false)
        connection.stub(:connect_frame => connect_frame)
        connection.stub(:serializer => OnStomp::Connections::Serializers::Stomp_1_0.new)
        connection.stub(:ready_for_write? => true)
        connection.stub(:write_nonblock) { raise EOFError }
        connection.stub(:io_process_read).with(true).and_yield(connected_frame)
        lambda do
          connection.connect(client)
        end.should raise_error(EOFError)
      end

      it "re-raises an EOFError raised while reading during connect" do
        io.stub(:closed? => false)
        connection.stub(:connect_frame => connect_frame)
        connection.stub(:serializer => OnStomp::Connections::Serializers::Stomp_1_0.new)
        connection.stub(:ready_for_read? => true)
        connection.stub(:read_nonblock) { raise EOFError }
        connection.stub(:io_process_write).and_yield(connect_frame)
        lambda do
          connection.connect(client)
        end.should raise_error(EOFError)
      end
    end
    
    describe ".configure" do
      let(:client_bindings) {
        { :died => nil, :established => nil }
      }
      it "should set its version parameter based on the supplied CONNECTED frame" do
        frame.stub(:header?).with(:version).and_return(true)
        frame.stub(:[]).with(:version).and_return('9.x')
        connection.should_receive(:install_bindings_from_client).with(client_bindings)
        connection.configure frame, client_bindings
        connection.version.should == '9.x'
      end
      it "should set its version parameter to 1.0 if the header is not present" do
        frame.stub(:header?).with(:version).and_return(false)
        connection.should_receive(:install_bindings_from_client).with(client_bindings)
        connection.configure frame, client_bindings
        connection.version.should == '1.0'
      end
    end
    
    describe "non-blocking IO wrappers" do
      before(:each) do
        io.stub(:closed? => false)
        io.stub(:read_nonblock => nil, :write_nonblock => 16)
      end
      
      it "should use read_nonblock if IO responds to read_nonblock" do
        io.should_receive(:read_nonblock).with(Base::MAX_BYTES_PER_READ)
        connection.stub(:ready_for_read? => true)
        connection.io_process_read
      end
      it "should use readpartial if IO does not respond to read_nonblock" do
        io.unstub(:read_nonblock)
        io.should_receive(:readpartial).with(Base::MAX_BYTES_PER_READ)
        connection.stub(:ready_for_read? => true)
        connection.io_process_read
      end
      
      it "should use write_nonblock if IO responds to write_nonblock" do
        io.should_receive(:write_nonblock).with("FRAME_SERIALIZED")
        connection.stub(:ready_for_write? => true)
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        connection.io_process_write
      end
      it "should use readpartial if IO does not respond to read_nonblock" do
        io.unstub(:write_nonblock)
        io.should_not respond_to(:write_nonblock)
        io.should_receive(:write).with("FRAME_SERIALIZED") { 16 }
        connection.push_write_buffer 'FRAME_SERIALIZED', frame
        connection.stub(:ready_for_write? => true)
        connection.io_process_write
      end
    end
  end
end
