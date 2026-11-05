class MethodChannel {
  final String name;
  const MethodChannel(this.name);
  Future<T?> invokeMethod<T>(String method) async => null;
}

class TestChannel {
  static final channel = MethodChannel('test/native');
  static final battery = MethodChannel('app/battery');
  static final camera = MethodChannel('app/camera');
  static final location = MethodChannel('app/location');

  void test() {
    battery.invokeMethod('getBatteryLevel');
    battery.invokeMethod('getBatteryStatus');
  }
}
