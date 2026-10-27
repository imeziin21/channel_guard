class MethodChannel {
  final String name;
  const MethodChannel(this.name);

}
class TestChannel{
  static final channel =  MethodChannel('test/native');
}