import 'dart:async';

enum ConnectState{
  idle, wificonnecting, wificonnected, tcpconnecting, tcpconnected, ftpconnecting, ftpconnected
}

// Singleton
AppState state = AppState();

class AppState{
  StreamController<ConnectState> _connectStateController = StreamController<ConnectState>();
  StreamSink<ConnectState> get _connectStateSink => _connectStateController.sink;
  Stream<ConnectState> get connectStateStream => _connectStateController.stream;
  ConnectState connectState = ConnectState.idle;

  AppState(){
    setState(ConnectState.idle);
  }

  setState(ConnectState state){
    if(state != connectState) {
      connectState = state;
      _connectStateSink.add(state);
    }
  }
}