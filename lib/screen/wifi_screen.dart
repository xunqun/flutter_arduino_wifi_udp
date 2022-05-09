import 'package:flutter/material.dart';

class WifiScreen extends StatefulWidget {
  const WifiScreen({Key? key}) : super(key: key);

  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  final TextEditingController ipController = TextEditingController(text: '192.168.4.1');
  final TextEditingController portController = TextEditingController(text: '1234');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            controller: ipController,
            decoration: InputDecoration(hintText: 'IP'),
          ),
          TextField(
            controller: portController,
            decoration: InputDecoration(hintText: 'Port'),
          ),
          ElevatedButton(onPressed: (){

          }, child: Text('Connect'))
        ],
      ),
    );
  }
}
