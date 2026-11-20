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

  static Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
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
