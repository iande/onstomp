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
      <td>{OnStomp::Interfaces::FrameMethods#abort abort}</td>
      <td>
        <code>abort(tx_id, headers={})</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#ack ack}</td>
      <td>
        <code>ack(message_id, headers={})</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #fbb;">false</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#ack ack}</td>
      <td>
        <code>ack(message_frame, headers={})</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#ack ack}</td>
      <td>
        <code>ack(message_id, subscription_id, headers={})</code>
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
      <td>{OnStomp::Interfaces::FrameMethods#begin begin}</td>
      <td>
        <code>begin(tx_id, headers={})</code>
      </td>
      <td style="background-color: #bfb;">true</td>
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
      <td>{OnStomp::Interfaces::FrameMethods#commit commit}</td>
      <td>
        <code>commit(tx_id, headers={})</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Client#connect connect}</td>
      <td>
        <code>connect(headers={})</code>
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
      <td>{OnStomp::Interfaces::FrameMethods#disconnect disconnect}</td>
      <td>
        <code>disconnect(headers={})</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Client#disconnect disconnect}</td>
      <td>
        <code>disconnect_with_flush(headers={})</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Client#disconnect_with_flush disconnect_with_flush}</td>
      <td>
        <code>disconnect_with_flush(headers={})</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Client#initialize initialize}</td>
      <td>
        <code>initialize(uri, options={})</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#nack nack}</td>
      <td>
        <code>nack(message_frame, headers={})</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#nack nack}</td>
      <td>
        <code>nack(message_id, subscription_id, heders={})</code>
      </td>
      <td style="background-color: #fbb;">false</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Client#open open}</td>
      <td>
        <code>connect(headers={})</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#puts puts}</td>
      <td>
        <code>send(dest, body, headers={}, &cb)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#send send}</td>
      <td>
        <code>send(dest, body, headers={}, &cb)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#subscribe subscribe}</td>
      <td>
        <code>subscribe(dest, headers={}, &cb)</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#unsubscribe unsubscribe}</td>
      <td>
        <code>unsubscribe(subscribe_frame, headers={})</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
    <tr>
      <td>{OnStomp::Interfaces::FrameMethods#unsubscribe unsubscribe}</td>
      <td>
        <code>unsubscribe(id, headers={})</code>
      </td>
      <td style="background-color: #bfb;">true</td>
      <td style="background-color: #bfb;">true</td>
    </tr>
  </tbody>
</table>

