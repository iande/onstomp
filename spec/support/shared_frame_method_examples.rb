shared_examples_for "frame method interfaces" do
  let(:shared_frame_method_headers) {
    { :header1 => 'value 1' }
  }
  let(:shared_frame_methods_transmit_callbacks) {
    Hash.new
  }
  
  before(:each) do
    if frame_method_interface.respond_to?(:connection)
      frame_method_interface.stub(
        :connection => OnStomp::Connections::Stomp_1_1.new(mock('io'), client)
      )
    end
  end
  
  describe ".send" do
    it "should transmit the result of connection.send_frame and callbacks" do
      frame_method_interface.should_receive(:transmit).
        with(an_onstomp_frame('SEND',
          [shared_frame_method_headers, {:destination => '/queue/test'}],
          'message body'), an_instance_of(Hash))
      frame_method_interface.send('/queue/test', 'message body', shared_frame_method_headers)
    end
    it "should be aliased as .puts" do
      frame_method_interface.should_receive(:transmit).
        with(an_onstomp_frame('SEND',
          [shared_frame_method_headers, {:destination => '/queue/test'}],
          'message body'), an_instance_of(Hash))
      frame_method_interface.puts('/queue/test', 'message body', shared_frame_method_headers)
    end
  end

  describe ".subscribe" do
    it "should transmit the result of connection.subscribe_frame and callbacks" do
      frame_method_interface.should_receive(:transmit).
        with(an_onstomp_frame('SUBSCRIBE',
          [shared_frame_method_headers, {:destination => '/queue/test'}]),
          an_instance_of(Hash))
      frame_method_interface.subscribe('/queue/test', shared_frame_method_headers)
    end
  end

  describe ".unsubscribe" do
    it "should transmit the result of connection.unsubscribe_frame" do
      frame_method_interface.should_receive(:transmit).
        with(an_onstomp_frame('UNSUBSCRIBE',
          [shared_frame_method_headers, {:id => 's-1234'}]))
      frame_method_interface.unsubscribe('s-1234', shared_frame_method_headers)
    end
  end

  describe ".begin" do
    it "should transmit the result of connection.begin_frame" do
      frame_method_interface.should_receive(:transmit).
        with(an_onstomp_frame('BEGIN',
          [shared_frame_method_headers, {:transaction => 't-1234'}]))
      frame_method_interface.begin('t-1234', shared_frame_method_headers)
    end
  end

  describe ".abort" do
    it "should transmit the result of connection.abort_frame" do
      frame_method_interface.should_receive(:transmit).
        with(an_onstomp_frame('ABORT',
          [shared_frame_method_headers, {:transaction => 't-1234'}]))
      frame_method_interface.abort('t-1234', shared_frame_method_headers)
    end
  end

  describe ".commit" do
    it "should transmit the result of connection.commit_frame" do
      frame_method_interface.should_receive(:transmit).
        with(an_onstomp_frame('COMMIT',
          [shared_frame_method_headers, {:transaction => 't-1234'}]))
      frame_method_interface.commit('t-1234', shared_frame_method_headers)
    end
  end

  describe ".disconnect" do
    it "should transmit the result of connection.disconnect_frame" do
      frame_method_interface.should_receive(:transmit).
        with(an_onstomp_frame('DISCONNECT',
          [shared_frame_method_headers]))
      frame_method_interface.disconnect(shared_frame_method_headers)
    end
  end

  describe ".ack" do
    it "should transmit the result of connection.ack_frame" do
      frame_method_interface.should_receive(:transmit).
        with(an_onstomp_frame('ACK',
          [shared_frame_method_headers, {:'message-id' => 'm-1234',
            :subscription => 's-5678'}]))
      frame_method_interface.ack('m-1234', 's-5678', shared_frame_method_headers)
    end
  end

  describe ".nack" do
    it "should transmit the result of connection.nack_frame" do
      frame_method_interface.should_receive(:transmit).
        with(an_onstomp_frame('NACK',
          [shared_frame_method_headers, {:'message-id' => 'm-1234',
            :subscription => 's-5678'}]))
      frame_method_interface.nack('m-1234', 's-5678', shared_frame_method_headers)
    end
  end

  describe ".beat" do
    it "should transmit the result of connection.heartbeat_frame" do
      frame_method_interface.should_receive(:transmit).
        with(an_onstomp_frame(nil))
      frame_method_interface.beat
    end
  end
end
