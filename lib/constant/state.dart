import 'dart:async';

enum ConnectState{
  idle, wificonnecting, wificonnected, tcpconnecting, tcpconnected,
}

// Singleton
State state = State();

class State{
  StreamController<ConnectState> _connectStateController = StreamController<ConnectState>();
  StreamSink<ConnectState> get _connectStateSink => _connectStateController.sink;
  Stream<ConnectState> get _connectStateStream => _connectStateController.stream;
  ConnectState connectState = ConnectState.idle;

  State(){
    setState(ConnectState.idle);
  }

  setState(ConnectState state){
    if(state != connectState) {
      connectState = state;
      _connectStateSink.add(state);
    }

  }
}