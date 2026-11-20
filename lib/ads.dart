import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// إعدادات الإعلانات.
/// رقم الإعلان الحقيقي بيتحط وقت البناء من GitHub Secrets (ADMOB_BANNER_ID).
/// لو مش موجود بيستخدم رقم Google التجريبي.
class Ads {
  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _bannerFromBuild = String.fromEnvironment('ADMOB_BANNER_ID');

  static String get bannerId =>
      _bannerFromBuild.isEmpty ? _testBannerId : _bannerFromBuild;

  static bool _started = false;

  /// بتبقى true بعد ما الإعلانات تتشغل (بعد خطوة الموافقة).
  static final ready = ValueNotifier<bool>(false);

  /// بيطلب موافقة المستخدم (لأوروبا وبريطانيا) لو مطلوبة، وبعدين يشغّل الإعلانات.
  static void init() {
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((_) => _start());
        },
        (_) => _start(),
      );
    } catch (_) {
      _start();
    }
  }

  static Future<void> _start() async {
    if (_started) return;
    _started = true;
    try {
      await MobileAds.instance.initialize();
      ready.value = true;
    } catch (_) {
      // التطبيق يشتغل عادي حتى لو الإعلانات فشلت.
    }
  }
}

class BannerAdBox extends StatefulWidget {
  const BannerAdBox({super.key});

  @override
  State<BannerAdBox> createState() => _BannerAdBoxState();
}

class _BannerAdBoxState extends State<BannerAdBox> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (Ads.ready.value) {
      _load();
    } else {
      Ads.ready.addListener(_onReady);
    }
  }

  void _onReady() {
    if (Ads.ready.value && _ad == null && mounted) {
      Ads.ready.removeListener(_onReady);
      _load();
    }
  }

  void _load() {
    _ad = BannerAd(
      adUnitId: Ads.bannerId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    Ads.ready.removeListener(_onReady);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
