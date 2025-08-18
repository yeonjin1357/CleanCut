import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // 테스트 광고 ID
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  // 실제 광고 ID (나중에 교체)
  // static const String _bannerAdUnitId = 'YOUR_ACTUAL_BANNER_AD_ID';
  // static const String _interstitialAdUnitId = 'YOUR_ACTUAL_INTERSTITIAL_AD_ID';

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;

  bool get isBannerAdReady => _isBannerAdReady;
  bool get isInterstitialAdReady => _isInterstitialAdReady;
  BannerAd? get bannerAd => _bannerAd;

  // AdMob 초기화
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    if (kDebugMode) {
      print('AdMob initialized');
    }
  }

  // 배너 광고 로드
  void loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _testBannerAdUnitId, // 테스트 ID 사용
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (kDebugMode) {
            print('Banner ad loaded');
          }
          _isBannerAdReady = true;
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          if (kDebugMode) {
            print('Banner ad failed to load: $error');
          }
          ad.dispose();
          _isBannerAdReady = false;
          _bannerAd = null;
        },
        onAdOpened: (Ad ad) {
          if (kDebugMode) {
            print('Banner ad opened');
          }
        },
        onAdClosed: (Ad ad) {
          if (kDebugMode) {
            print('Banner ad closed');
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  // 전면 광고 로드
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _testInterstitialAdUnitId, // 테스트 ID 사용
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          if (kDebugMode) {
            print('Interstitial ad loaded');
          }
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          // 전면 광고 리스너 설정
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              if (kDebugMode) {
                print('Interstitial ad dismissed');
              }
              ad.dispose();
              _isInterstitialAdReady = false;
              // 다음 광고를 위해 미리 로드
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              if (kDebugMode) {
                print('Interstitial ad failed to show: $error');
              }
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) {
            print('Interstitial ad failed to load: $error');
          }
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  // 전면 광고 표시
  Future<void> showInterstitialAd() async {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      await _interstitialAd!.show();
    } else {
      if (kDebugMode) {
        print('Interstitial ad is not ready yet');
      }
      // 광고가 준비되지 않았으면 다시 로드 시도
      loadInterstitialAd();
    }
  }

  // 배너 광고 위젯 반환
  Widget? getBannerAdWidget() {
    if (kDebugMode) {
      print('Getting banner ad widget: ready=$_isBannerAdReady, ad=${_bannerAd != null}');
    }
    if (_isBannerAdReady && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return null;
  }

  // 리소스 정리
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}