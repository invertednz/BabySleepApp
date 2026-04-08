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
      _mixpanel = await Mixpanel.init(
        token,
        trackAutomaticEvents: true,
        // Use IDFV (Identifier for Vendor) instead of IDFA to avoid
        // requiring the App Tracking Transparency prompt.
        // IDFV is scoped to the app vendor and doesn't require user consent.
        optOutTrackingDefault: false,
      );
    } catch (_) {
      // Initialization failed silently
    }
  }

  void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    final mixpanel = _mixpanel;
    if (mixpanel == null) {
      return;
    }
    mixpanel.track(eventName, properties: properties);
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
