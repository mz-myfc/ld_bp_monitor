import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../ble/ble.dart';
import '../ble/notifier.dart';
import 'view/loading.dart';
import 'view/popup.dart';
import 'view/toast.dart';

class Load {
  static final Load h = Load._();

  Load._();

  void dismiss() async => await SmartDialog.dismiss();

  ///Toast
  void toast({String msg = ''}) async {
    await SmartDialog.showToast(
      '',
      builder: (_) => ToastPop(msg: msg),
      displayType: SmartToastType.last,
    );
  }

  ///Animation
  void loadAnimation({String? msg}) async {
    dismiss();
    await SmartDialog.show(
      builder: (_) => LoadAnimation(msg: msg),
    ).timeout(const Duration(minutes: 1), onTimeout: dismiss);
  }

  void showDevicePop() async {
    dismiss();
    await SmartDialog.show(
      builder:
          (_) => ChangeNotifierProvider(
            data: Ble.helper,
            child: Consumer<Ble>(
              builder:
                  (context, helper) => Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.inversePrimary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text('Devices', style: TextStyle(fontSize: 15)),
                              Positioned(
                                right: 10,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: dismiss,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          child: ListView.separated(
                            itemCount: helper.myDeviceArray.length,
                            itemBuilder: (context, index) {
                              var device = helper.myDeviceArray[index];
                              return ListTile(
                                title: Text(
                                  bleName(device.name),
                                  style: TextStyle(fontSize: 13),
                                ),
                                subtitle: Stack(
                                  children: [
                                    Text(
                                      "${device.id}\nRssi: ${device.rssi}",
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    Container(
                                      alignment: Alignment.bottomRight,
                                      margin: const EdgeInsets.only(top: 30),
                                      child: TextButton(
                                        onPressed: () async {
                                          Load.h.dismiss();
                                          await Ble.helper.connect(device);
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.grey.shade50,
                                        ),
                                        child: Text(
                                          "Connect",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  dismiss();
                                  await helper.connect(device);
                                },
                              );
                            },
                            separatorBuilder:
                                (context, index) => Divider(
                                  height: 0.5,
                                  color: Colors.grey.shade300,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
    );
  }

  //bluetooth names
  String bleName(String name) {
    return name.trim().replaceAll(RegExp(r'\u0000+$'), '');
  }

  //Popup
  void show({required String msg, VoidCallback? onTap}) async {
    dismiss();
    await SmartDialog.show(builder: (_) => Popup(msg: msg, onTap: onTap));
  }
}
