# OnStomp Generated Method APIs

## OnStomp 1 API (1.0.0+)

<table style="width:75%; border-collapse:collapse;">
  <thead>
    <tr>
      <th style="text-align: left;">Method</th>
      <th style="width: 50%; text-align: left;">Signature</th>
      <th style="text-align: left;">STOMP 1.0</th>
      <th style="text-align: left;">STOMP 1.1</th>
    </tr>
  </thead>
  <tfoot>
  </tfoot>
  <tbody>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#:begin :begin}</td>
      <td>
        <code>:begin</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#abort abort}</td>
      <td>
        <code>abort</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#abort abort}</td>
      <td>
        <code>abort(tx_id, headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#ack ack}</td>
      <td>
        <code>ack</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#ack ack}</td>
      <td>
        <code>ack(message_frame, headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#ack ack}</td>
      <td>
        <code>ack(message_id, subscription_id, headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#ack ack}</td>
      <td>
        <code>ack(message_id, headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #fbb;">false</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#after_receiving after_receiving}</td>
      <td>
        <code>create_event_methods :receiving, :before, :after</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#after_transmitting after_transmitting}</td>
      <td>
        <code>create_event_methods :transmitting, :before, :after</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#beat beat}</td>
      <td>
        <code>beat( )</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_abort before_abort}</td>
      <td>
        <code>create_event_methods :abort, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_ack before_ack}</td>
      <td>
        <code>create_event_methods :ack, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_begin before_begin}</td>
      <td>
        <code>create_event_methods :begin, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_broker_beat before_broker_beat}</td>
      <td>
        <code>create_event_methods :broker_beat, :before, :on</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_client_beat before_client_beat}</td>
      <td>
        <code>create_event_methods :client_beat, :before, :on</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_commit before_commit}</td>
      <td>
        <code>create_event_methods :commit, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_disconnect before_disconnect}</td>
      <td>
        <code>create_event_methods :disconnect, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_error before_error}</td>
      <td>
        <code>create_event_methods :error, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_message before_message}</td>
      <td>
        <code>create_event_methods :message, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_nack before_nack}</td>
      <td>
        <code>create_event_methods :nack, :before, :on</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_receipt before_receipt}</td>
      <td>
        <code>create_event_methods :receipt, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_receiving before_receiving}</td>
      <td>
        <code>create_event_methods :receiving, :before, :after</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_send before_send}</td>
      <td>
        <code>create_event_methods :send, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_subscribe before_subscribe}</td>
      <td>
        <code>create_event_methods :subscribe, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_transmitting before_transmitting}</td>
      <td>
        <code>create_event_methods :transmitting, :before, :after</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#before_unsubscribe before_unsubscribe}</td>
      <td>
        <code>create_event_methods :unsubscribe, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#begin begin}</td>
      <td>
        <code>begin(tx_id, headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ConnectionEvents#blocked blocked}</td>
      <td>
        <code>blocked</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#broker_beat broker_beat}</td>
      <td>
        <code>broker_beat</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#client_beat client_beat}</td>
      <td>
        <code>client_beat</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Client#close! close!}</td>
      <td>
        <code>close!( )</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ConnectionEvents#closed closed}</td>
      <td>
        <code>closed</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#commit commit}</td>
      <td>
        <code>commit</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#commit commit}</td>
      <td>
        <code>commit(tx_id, headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#connect connect}</td>
      <td>
        <code>connect</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Client#connect connect}</td>
      <td>
        <code>connect(headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Client#connected? connected?}</td>
      <td>
        <code>connected?( )</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ConnectionEvents#died died}</td>
      <td>
        <code>died</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#disconnect disconnect}</td>
      <td>
        <code>disconnect</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Client#disconnect disconnect}</td>
      <td>
        <code>disconnect_with_flush(headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#disconnect disconnect}</td>
      <td>
        <code>disconnect(headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Client#disconnect_with_flush disconnect_with_flush}</td>
      <td>
        <code>disconnect_with_flush(headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#error error}</td>
      <td>
        <code>error</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ConnectionEvents#established established}</td>
      <td>
        <code>established</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Client#initialize initialize}</td>
      <td>
        <code>initialize(uri, options=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#message message}</td>
      <td>
        <code>message</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#nack nack}</td>
      <td>
        <code>nack(message_frame, headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#nack nack}</td>
      <td>
        <code>nack</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#nack nack}</td>
      <td>
        <code>nack(message_id, subscription_id, heders=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_abort on_abort}</td>
      <td>
        <code>create_event_methods :abort, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_ack on_ack}</td>
      <td>
        <code>create_event_methods :ack, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_begin on_begin}</td>
      <td>
        <code>create_event_methods :begin, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ConnectionEvents#on_blocked on_blocked}</td>
      <td>
        <code>create_event_methods :blocked, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_broker_beat on_broker_beat}</td>
      <td>
        <code>create_event_methods :broker_beat, :before, :on</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_client_beat on_client_beat}</td>
      <td>
        <code>create_event_methods :client_beat, :before, :on</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ConnectionEvents#on_closed on_closed}</td>
      <td>
        <code>create_event_methods :closed, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_commit on_commit}</td>
      <td>
        <code>create_event_methods :commit, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_connect on_connect}</td>
      <td>
        <code>create_event_methods :connect, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ConnectionEvents#on_died on_died}</td>
      <td>
        <code>create_event_methods :died, :on</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_disconnect on_disconnect}</td>
      <td>
        <code>create_event_methods :disconnect, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_error on_error}</td>
      <td>
        <code>create_event_methods :error, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ConnectionEvents#on_established on_established}</td>
      <td>
        <code>create_event_methods :established, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_message on_message}</td>
      <td>
        <code>create_event_methods :message, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_nack on_nack}</td>
      <td>
        <code>create_event_methods :nack, :before, :on</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_receipt on_receipt}</td>
      <td>
        <code>create_event_methods :receipt, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_send on_send}</td>
      <td>
        <code>create_event_methods :send, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_subscribe on_subscribe}</td>
      <td>
        <code>create_event_methods :subscribe, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ConnectionEvents#on_terminated on_terminated}</td>
      <td>
        <code>create_event_methods :terminated, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#on_unsubscribe on_unsubscribe}</td>
      <td>
        <code>create_event_methods :unsubscribe, :before, :on</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Client#open open}</td>
      <td>
        <code>connect(headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#puts puts}</td>
      <td>
        <code>send(dest, body, headers=&lt;optional hash&gt;, &cb)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#receipt receipt}</td>
      <td>
        <code>receipt</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#receiving receiving}</td>
      <td>
        <code>receiving</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#send send}</td>
      <td>
        <code>send(dest, body, headers=&lt;optional hash&gt;, &cb)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#send send}</td>
      <td>
        <code>send</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#subscribe subscribe}</td>
      <td>
        <code>subscribe</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#subscribe subscribe}</td>
      <td>
        <code>subscribe(dest, headers=&lt;optional hash&gt;, &cb)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ConnectionEvents#terminated terminated}</td>
      <td>
        <code>terminated</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#transmitting transmitting}</td>
      <td>
        <code>transmitting</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#unsubscribe unsubscribe}</td>
      <td>
        <code>unsubscribe(subscribe_frame, headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#unsubscribe unsubscribe}</td>
      <td>
        <code>unsubscribe(id, headers=&lt;optional hash&gt;)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::ClientEvents#unsubscribe unsubscribe}</td>
      <td>
        <code>unsubscribe</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
  </tbody>
</table>

