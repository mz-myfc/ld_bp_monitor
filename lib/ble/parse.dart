import 'package:flutter/material.dart';

/*
 * Parse
 */
class Parse extends ChangeNotifier {
  static final Parse helper = Parse._();

  Parse._();

  void refresh() => notifyListeners();

  /*
   * error info
   * 0=Device cannot be inflated
   * 1=An error occurred during measurement, please measure correctly
   * 2=Low battery of sphygmomanometer
   * 3=Cancel (custom)
   */
  int errMsg = -1;
  int hb = 0; // heart beat(0 | 1)
  int pressure = 0; // pressure
  int hr = 0; // heart rate(0~255)
  int sys = 0; // systolic pressure(0~255)
  int dia = 0; // diastolic pressure(0~255)
  int ihb = 0; // irregular heart beat(0 | 1)
  int bat = 100; // battery
}

extension Analysis on Parse {
  void analyze(List<int> array) {
    if (array.length < 5 || xff(array[1]) != 0xff || xff(array[2]) != 0xff) {
      return;
    }
    switch (array[3]) {
      case 0x05:
        if (array[4] == 0x04) _onError(3); // cancel
        break;
      case 0x06:
        if (array.length < 6) return;
        if (array[4] == 0x07) {
          _onError(xff(array[5])); // measurement error
        } else if (array[4] == 0x09) {
          bat = xff(array[5], 0, 100); // battery
        }
        break;
      case 0x0A:
        if (array.length < 10 || array[4] != 0x02) return;
        hb = xff(array[5], 0, 1); // measuring
        pressure = xff(xff(array[6]) | (array[7] << 8 & 0xff00), 0, 300); // pressure
        _onStart(hb, pressure);
        break;
      case 0x49:
        if (array[4] == 0x03) _onFinish(array);
        break;
    }
  }

  // range
  int xff(int v, [int n = 0, int x = 255]) => v.clamp(n, x) & 0xFF;
}

extension Result on Parse {
  void _onStart(int hb, int pressure) => onChange(hb, pressure, 0, 0, 0, 0, 0, -1);

  void _onFinish(List<int> array) {
    if (array.isEmpty || array.length < 9) return;
    hr = xff(array[5]);
    sys = xff(array[6]) + 30;
    dia = xff(array[7]) + 30;
    ihb = xff(array[8]);
    onChange(0, 0, hr, sys, dia, ihb, bat, -1);
  }

  void _onError(int e) => onChange(0, 0, hr, sys, dia, 0, bat, e);
}

extension Value on Parse {
  void init() {
    errMsg = -1;
    hb = 0;
    pressure = 0;
    hr = 0;
    sys = 0;
    dia = 0;
    ihb = 0;
    bat = 100;
  }

  // listen
  void onChange(int hb, int pressure, int hr, int sys, int dia, int ihb, int bat, int errMsg) {
    this.hb = hb;
    this.pressure = pressure;
    this.hr = hr;
    this.sys = sys;
    this.dia = dia;
    this.ihb = ihb;
    this.bat = bat;
    this.errMsg = errMsg;
    refresh();
  }

  // error message
  String errMsgStr() {
    switch(errMsg){
      case 0:
        return 'Unable to inflate.';
      case 1:
        return 'An error occurred during measurement, please measure correctly.';
      case 2:
        return 'Sphygmomanometer battery is too low.';
      case 3:
        return 'Measurement canceled.';
      default:
        return '--';
    }
  }
}
