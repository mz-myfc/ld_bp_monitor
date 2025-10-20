import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../pop/load.dart';
import 'ble.dart';

class PermissionHelper {
  static PermissionHelper ph = PermissionHelper._();

  PermissionHelper._();

  Future<void> scanBle() async {
    var bleStatus = Ble.helper.bleStatus;
    if (Platform.isIOS) {
      await Permission.bluetooth.request();
      if (bleStatus == BleStatus.ready) {
        await Ble.helper.startScan();
      }
    } else {
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();
      switch (bleStatus) {
        case BleStatus.ready:
          await Ble.helper.startScan();
          break;
        case BleStatus.unauthorized:
          await Permission.location.request().then((value) {
            if (value.isDenied || value.isPermanentlyDenied) {
              Load.h.show(
                msg: "Please turn on location",
                onTap: openAppSettings,
              );
            }
          });
          break;
        case BleStatus.locationServicesDisabled:
          Load.h.show(msg: "Please turn on location", onTap: openLocation);
          break;
        case BleStatus.poweredOff:
          Load.h.show(msg: "Please turn on bluetooth", onTap: openBluetooth);
          break;
        case BleStatus.unknown:
        case BleStatus.unsupported:
          Load.h.toast(msg: "Please check the bluetooth status");
          break;
      }
    }
  }

  void openLocation() {
    Load.h.dismiss();
    AppSettings.openAppSettings(type: AppSettingsType.location);
  }

  void openAppSettings() {
    Load.h.dismiss();
    AppSettings.openAppSettings();
  }

  void openBluetooth() {
    Load.h.dismiss();
    AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
  }
}
