import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wifi_udp/screen/page_controller.dart';
import 'package:flutter_wifi_udp/screen/page_file.dart';
import 'package:flutter_wifi_udp/screen/page_terminal.dart';

import '../constant/state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _index = 0;
  final _pages = kDebugMode ? const [ControllerPage(), FilePage(),  TerminalPage()] : const [ControllerPage(), FilePage()] ;

  StreamSubscription<ConnectState>? stateSubs;

  @override
  void initState() {
    super.initState();
    stateSubs = appState.connectStateStream.listen((event) {
      if(event == ConnectState.idle){
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    stateSubs?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        items: kDebugMode ? const [
          BottomNavigationBarItem(icon: Icon(Icons.tune), label: '控制項'),
          BottomNavigationBarItem(icon: Icon(Icons.file_copy_outlined), label: '聲音目錄'),
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: '指令紀錄'),
        ] :const [
          BottomNavigationBarItem(icon: Icon(Icons.tune), label: '控制項'),
          BottomNavigationBarItem(icon: Icon(Icons.file_copy_outlined), label: '聲音目錄'),
        ],
        onTap: (i){
          setState(() {
            _index = i;
          });
        },
      ),
    );
  }
}
