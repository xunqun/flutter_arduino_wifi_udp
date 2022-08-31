import 'package:flutter/material.dart';
import 'package:flutter_wifi_udp/screen/page_controller.dart';
import 'package:flutter_wifi_udp/screen/page_file.dart';
import 'package:flutter_wifi_udp/screen/page_settings.dart';
import 'package:flutter_wifi_udp/screen/page_terminal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _index = 0;
  final _pages = const [TerminalPage(),  ControllerPage(), FilePage(), SettingPage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Terminal'),
          BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Controller'),
          BottomNavigationBarItem(icon: Icon(Icons.file_copy), label: 'File'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings')
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
