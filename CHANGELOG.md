# Changes

## 1.0.3
* change how failover spawns new connections when failing over.

## 1.0.2
* allow failover clients to be constructed from regular OnStomp::Client
  instances, allowing fully configured SSL connections.

## 1.0.1
* improved failover buffer handling
* added RECEIPT driven failover buffer handling - more reliable, but slower
  as it requests receipts for nearly all frames.

## 1.0.0
* initial release
* support for STOMP 1.0 and STOMP 1.1 protocols
* fully featured client with event bindings and non-blocking IO
* experimental support for open-uri STOMP interface
* experimental support for failover/reliable connection handling

## 1.0pre - 2011-03-30
* initial pre-release
