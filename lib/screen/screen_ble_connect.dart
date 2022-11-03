import 'dart:io';

import 'package:flutter/material.dart';

class BleConnectScreen extends StatefulWidget {
  const BleConnectScreen({Key? key}) : super(key: key);

  @override
  State<BleConnectScreen> createState() => _BleConnectScreenState();
}

class _BleConnectScreenState extends State<BleConnectScreen> {
  var stateDesc = '點擊連線以連線到閃爍器';
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 64,
            child: ElevatedButton(onPressed: (){}, child: Text('連線'), style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36.0),
                        side: BorderSide(color: Colors.white)
                    )
                )
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(stateDesc, style: TextStyle(fontSize: 12, color: Colors.grey), ),
          )
        ],
      ),
    );
  }
}
