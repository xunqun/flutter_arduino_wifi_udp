import 'package:flutter/material.dart';
import 'package:flutter_wifi_udp/manager/udp_manager.dart';
import 'package:flutter_wifi_udp/screen/screen_ble_connect.dart';
import 'package:flutter_wifi_udp/screen/screen_connect.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'manager/log_manager.dart';
import 'manager/settings.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var granted = false;

  @override
  void initState() {
    super.initState();
    checkPermission().then((value) {
      setState(() {
        granted = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: logManager),
        ChangeNotifierProvider.value(value: udpManager),
        ChangeNotifierProvider.value(value: settings)
      ],
      child: MaterialApp(
        title: 'Wifi UDP Client',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: check(),
      ),
    );
  }

  Future<bool> checkPermission() async {
    var success = true;
    success = success && await Permission.bluetoothConnect.isGranted;
    success = success && await Permission.bluetoothScan.isGranted;
    success = success && await Permission.locationWhenInUse.isGranted;
    // success = success && await Permission.bluetooth.isGranted;
    return success;
  }

  Widget check() {
    if (!granted) {
      return PermissionPage(callback: () {
        checkPermission().then((value) => setState(() {
          granted = value;
        }));
      });
    } else {
      return const BleConnectScreen();
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class PermissionPage extends StatelessWidget {
  VoidCallback callback;

  PermissionPage({Key? key, required this.callback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("需要允許藍芽、位置權限，以運行此APP"),
            const SizedBox(
              height: 16,
            ),
            ElevatedButton(
                onPressed: () {
                  requestPermission();
                },
                child: const Text("允許權限"))
          ],
        ),
      ),
    );
  }

  void requestPermission() async {
    await [Permission.bluetoothConnect, Permission.bluetooth, Permission.bluetoothScan, Permission.locationAlways]
        .request();
    callback();
  }
}