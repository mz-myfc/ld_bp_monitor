// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ld_bp_monitor/ble/parse.dart';
import 'package:ld_bp_monitor/pop/load.dart';

/*
 * Bluetooth  
 */
class Ble extends ChangeNotifier {
  static final Ble helper = Ble._();

  Ble._();

  void refresh() => notifyListeners();

  static Uuid BLE_SERVICE    = Uuid.parse("01000000-0000-0000-0000-000000000080");
  static Uuid BLE_READ_WRITE = Uuid.parse("05000000-0000-0000-0000-000000000080");
  static Uuid BLE_NOTIFY     = Uuid.parse("02000000-0000-0000-0000-000000000080");
  static Uuid BLE_READ       = Uuid.parse("04000000-0000-0000-0000-000000000080");
  static Uuid NAME           = Uuid.parse("00002a37-0000-1000-8000-00805f9b34fb");
  static Uuid MANUFACTURER_NAME = Uuid.parse("00002a29-0000-1000-8000-00805f9b34fb");

  /*
   * Hex
   */
  static List<int> CMD_START       = [0xFF, 0xFF, 0x05, 0x01, 0xFA]; // Start
  static List<int> CMD_CANCEL      = [0xFF, 0xFF, 0x05, 0x04, 0xF7]; // Cancel

  final ble = FlutterReactiveBle(); // Bluetooth instance
  BleStatus bleStatus = BleStatus.unknown; // Bluetooth status

  StreamSubscription<DiscoveredDevice>? scanSubscription; // Scan stream
  StreamSubscription<ConnectionStateUpdate>? connSubscription; // Connected device stream
  List<DiscoveredDevice> myDeviceArray = []; // Device list
  DiscoveredDevice? currentDevice; // Current device
}

extension BluetoothExtension on Ble {
  Future<void> bleState() async {
    ble.statusStream.listen((status) => bleStatus = status);
    ble.connectedDeviceStream.listen((e) {
      if (e.connectionState == DeviceConnectionState.disconnected) {
        disconnect();
        Load.h.dismiss();
      }
    });
  }

  //Scan Ble
  Future<void> startScan() async {
    myDeviceArray = [];
    Parse.helper.init();
    Load.h.showDevicePop();
    Future.delayed(const Duration(seconds: 1), () {
      disconnect();
      scanSubscription = ble.scanForDevices(
        withServices: [],
        scanMode: ScanMode.lowLatency,
      ).listen((e) => deviceList(e),
        onError: (_) => disconnect(),
      );
    });
  }

  // device list processing
  Future<void> deviceList(DiscoveredDevice device) async {
    if (device.name.isEmpty) return;
    var index = myDeviceArray.indexWhere((e) => e.id == device.id);
    if (index >= 0) {
      myDeviceArray[index] = device;
    } else {
      myDeviceArray.add(device);
    }
    myDeviceArray.sort((a, b) => b.rssi.compareTo(a.rssi));
    refresh();
  }

  //stop scanning
  void _stopScan() {
    scanSubscription?.cancel();
    scanSubscription = null;
  }

  // disconnect
  void disconnect() async {
    try {
      if (Platform.isAndroid && currentDevice != null) {
        await ble.clearGattCache(currentDevice!.id);
      }
    } catch (_) {}
    _stopScan();
    connSubscription?.cancel();
    connSubscription = null;
    currentDevice = null;
    Parse.helper.init();
  }

  Future<void> connect(DiscoveredDevice device) async {
    disconnect();
    connSubscription = ble.connectToDevice(
      id: device.id,
      servicesWithCharacteristicsToDiscover: {
        Ble.BLE_SERVICE: [Ble.BLE_NOTIFY, Ble.BLE_READ_WRITE]
      },
    ).listen((state) => _listener(state, device),
      onError: (_) => disconnect(),
    );
  }

  void _listener(
      ConnectionStateUpdate connectionState, DiscoveredDevice device) {
    switch (connectionState.connectionState) {
      case DeviceConnectionState.connecting:
        Load.h.loadAnimation(msg: 'Connecting...');
        break;
      case DeviceConnectionState.connected:
        _stopScan();
        currentDevice = device;
        Load.h.dismiss();
        Load.h.toast(msg: 'Connected');
        _listenToData(); //Listen to data
        break;
      case DeviceConnectionState.disconnecting:
        break;
      case DeviceConnectionState.disconnected:
        disconnect();
        Load.h.dismiss();
        break;
    }
  }

  void _listenToData() {
    if (currentDevice == null) return;
    final characteristic = QualifiedCharacteristic(
      serviceId: Ble.BLE_SERVICE,
      characteristicId: Ble.BLE_NOTIFY,
      deviceId: currentDevice!.id,
    );
    ble
        .subscribeToCharacteristic(characteristic)
        .listen((data) => Parse.helper.analyze(data),
        onError: (_) => disconnect());
  }

  //write hex
  void writeHex(List<int> hex) async {
    if (currentDevice == null || hex.isEmpty) return;
    final characteristic = QualifiedCharacteristic(
      serviceId: Ble.BLE_SERVICE,
      characteristicId: Ble.BLE_READ_WRITE,
      deviceId: currentDevice!.id,
    );
    await ble.writeCharacteristicWithResponse(characteristic, value: hex).catchError((_) {});
  }
}
