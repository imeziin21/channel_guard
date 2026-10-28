class MethodChannel {
  final String name;
  const MethodChannel(this.name);

}
class TestChannel{
  static final channel =  MethodChannel('test/native');
  static final battery = MethodChannel('app/battery');
  static final camera = MethodChannel('app/camera');
  static final location = MethodChannel('app/location');
}