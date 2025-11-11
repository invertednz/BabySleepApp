import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:babysteps_app/config/mixpanel_config.dart';

class MixpanelService {
  Mixpanel? _mixpanel;

  MixpanelService._internal();

  static final MixpanelService _instance = MixpanelService._internal();

  factory MixpanelService() => _instance;

  Mixpanel? get client => _mixpanel;

  Future<void> initialize() async {
    if (_mixpanel != null) {
      return;
    }

    final token = MixpanelConfig.mixpanelToken;
    if (token.isEmpty) {
      return;
    }

    try {
      _mixpanel = await Mixpanel.init(token, trackAutomaticEvents: true);
    } catch (e) {
      debugPrint('Mixpanel initialization failed: $e');
    }
  }

  void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    final mixpanel = _mixpanel;
    if (mixpanel == null) {
      return;
    }
    mixpanel.track(eventName, properties: properties);
  }

  void identify(String distinctId) {
    final mixpanel = _mixpanel;
    if (mixpanel == null || distinctId.trim().isEmpty) {
      return;
    }
    mixpanel.identify(distinctId);
  }

  void setPeopleProperties(Map<String, dynamic> properties) {
    final mixpanel = _mixpanel;
    if (mixpanel == null || properties.isEmpty) {
      return;
    }
    final people = mixpanel.getPeople();
    properties.forEach((key, value) {
      people.set(key, value);
    });
  }

  void reset() {
    final mixpanel = _mixpanel;
    if (mixpanel == null) {
      return;
    }
    mixpanel.reset();
  }

  Future<void> flush() async {
    final mixpanel = _mixpanel;
    if (mixpanel == null) {
      return;
    }
    await mixpanel.flush();
  }
}
