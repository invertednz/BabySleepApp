import 'package:flutter_dotenv/flutter_dotenv.dart';

class MixpanelConfig {
  static String get mixpanelToken => (dotenv.env['MIXPANEL_TOKEN'] ?? '').trim();
}
