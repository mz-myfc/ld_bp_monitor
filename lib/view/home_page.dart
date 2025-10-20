import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../ble/ble.dart';
import '../ble/notifier.dart';
import '../ble/parse.dart';
import '../ble/permission.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () async {
      await WakelockPlus.enable();
      await Ble.helper.bleState();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('BP', style: TextStyle(fontSize: 18)),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        IconButton(
          icon: const Icon(Icons.bluetooth),
          onPressed: () async {
            await PermissionHelper.ph.scanBle();
          },
        ),
      ],
    ),
    body: ChangeNotifierProvider(
      data: Parse.helper,
      child: Consumer<Parse>(
        builder:
            (context, helper) => Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  height: 430,
                  child: Flex(
                    direction: Axis.vertical,
                    children: [
                      Expanded(
                        child: _Item(
                          title: 'SYS / DIA',
                          unit: 'mmHg',
                          value: [helper.sys, helper.dia],
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: _Item(
                          title: 'HR',
                          unit: 'bpm',
                          value: helper.hr,
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: _Item(
                          title: 'PRESSURE',
                          unit: 'mmHg',
                          value: helper.pressure,
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: _Item(
                          title: 'ERROR',
                          unit: '',
                          fontSize: 15,
                          value: helper.errMsgStr(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      child: Text('Start', style: TextStyle(fontSize: 13)),
                      onPressed: () {
                        Ble.helper.writeHex(Ble.CMD_START);
                      },
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      child: Text('Cancel', style: TextStyle(fontSize: 13)),
                      onPressed: () {
                        Ble.helper.writeHex(Ble.CMD_CANCEL);
                      },
                    ),
                  ],
                ),
              ],
            ),
      ),
    ),
  );

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.title,
    required this.unit,
    required this.value,
    this.fontSize = 25,
  });

  final String title;
  final String unit;
  final dynamic value;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      color: Colors.deepPurple.shade50,
      border: Border.all(width: 0.5, color: Colors.grey),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 3,
          left: 3,
          child: Text(title, style: TextStyle(fontSize: 13)),
        ),
        Text(_text(), style: TextStyle(fontSize: fontSize), maxLines: 2),
        Positioned(
          right: 3,
          bottom: 3,
          child: Text(unit, style: TextStyle(fontSize: 13)),
        ),
      ],
    ),
  );

  String _text() {
    if (value is List && value.length >= 2) {
      final sys = value[0] > 0 ? value[0] : '--';
      final dia = value[1] > 0 ? value[1] : '--';
      return '$sys/$dia';
    }
    if (value is int) return value > 0 ? '$value' : '--';
    if (value is String) return value;
    return '--';
  }
}
