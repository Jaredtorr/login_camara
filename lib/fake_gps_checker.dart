import 'package:detect_fake_location/detect_fake_location.dart';

class FakeGpsChecker {

  static Future<bool> isFakeGpsActive() async {
    return await DetectFakeLocation().detectFakeLocation();
  }
}