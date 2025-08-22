import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // 테스트 광고 ID (개발용)
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  
  // 실제 광고 ID (프로덕션용) - 실제 ID로 교체 필요
  static const String _prodBannerAdUnitId = 'YOUR_ACTUAL_BANNER_AD_ID';
  static const String _prodInterstitialAdUnitId = 'YOUR_ACTUAL_INTERSTITIAL_AD_ID';
  
  // 현재 사용할 광고 ID (임시로 모든 환경에서 테스트 ID 사용)
  // TODO: 실제 광고 ID 받으면 아래 주석 해제하고 위 라인 삭제
  String get bannerAdUnitId => _testBannerAdUnitId;  // 임시: 테스트 광고
  String get interstitialAdUnitId => _testInterstitialAdUnitId;  // 임시: 테스트 광고
  // String get bannerAdUnitId => kDebugMode ? _testBannerAdUnitId : _prodBannerAdUnitId;
  // String get interstitialAdUnitId => kDebugMode ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;

  // 광고 인스턴스
  BannerAd? _homeBannerAd;
  BannerAd? _editorBannerAd;
  InterstitialAd? _interstitialAd;
  InterstitialAd? _preloadedInterstitialAd; // 미리 로드한 광고
  
  // 적응형 배너 크기
  AdSize? _adaptiveBannerSize;
  
  // 광고 준비 상태
  bool _isHomeBannerAdReady = false;
  bool _isEditorBannerAdReady = false;
  bool _isInterstitialAdReady = false;
  bool _isPreloadedInterstitialReady = false;
  
  // 로드 중 상태 플래그 추가
  bool _isLoadingInterstitialAd = false;
  bool _isLoadingPreloadedAd = false;
  
  // 재시도 관련
  static const int _maxRetryAttempts = 3;
  static const int _initialRetryDelay = 2; // 초
  final Map<String, int> _retryAttempts = {
    'homeBanner': 0,
    'editorBanner': 0,
    'interstitial': 0,
  };
  
  // 타이머
  Timer? _homeBannerRetryTimer;
  Timer? _editorBannerRetryTimer;
  Timer? _interstitialRetryTimer;
  Timer? _interstitialAutoLoadTimer;
  Timer? _interstitialLoadTimeoutTimer;
  

  bool get isHomeBannerAdReady => _isHomeBannerAdReady;
  bool get isEditorBannerAdReady => _isEditorBannerAdReady;
  bool get isInterstitialAdReady => _isInterstitialAdReady || _isPreloadedInterstitialReady;

  // AdMob 초기화 (최적화 플래그 포함)
  Future<void> initialize() async {
    try {
      
      // 테스트 디바이스 설정
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        testDeviceIds: <String>[
          'EMULATOR',
          'SIMULATOR',
          if (kDebugMode) 'YOUR_TEST_DEVICE_ID', // 실제 테스트 기기 ID
        ],
      );
      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
      
      // 초기화 (최적화 플래그 사용)
      await MobileAds.instance.initialize();
      
      
      // 적응형 배너 크기 미리 계산 (기본값)
      _adaptiveBannerSize = AdSize.banner;
      
      // 초기화 후 광고 미리 로드
      Future.delayed(const Duration(seconds: 1), () {
        preloadAds();
      });
      
      // 주기적으로 전면 광고 상태 확인 및 자동 로드
      _interstitialAutoLoadTimer?.cancel();
      _interstitialAutoLoadTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        if (!_isInterstitialAdReady && !_isPreloadedInterstitialReady && 
            !_isLoadingInterstitialAd && !_isLoadingPreloadedAd) {
          print('[AdService] 전면 광고 자동 재로드 시도');
          loadInterstitialAd();
        }
      });
      
    } catch (e) {
    }
  }
  
  // 적응형 배너 크기 업데이트
  Future<void> updateAdaptiveBannerSize(BuildContext context) async {
    try {
      final width = MediaQuery.of(context).size.width.truncate();
      _adaptiveBannerSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      _adaptiveBannerSize ??= AdSize.banner; // 실패 시 기본값
    } catch (e) {
      _adaptiveBannerSize = AdSize.banner;
    }
  }
  
  // 광고 미리 로드
  void preloadAds() {
    loadHomeBannerAd();
    loadEditorBannerAd();
    loadInterstitialAd();
    // 약간의 지연 후 두 번째 전면 광고 로드
    Future.delayed(const Duration(seconds: 2), () {
      _preloadNextInterstitialAd();
    });
  }

  // 홈 화면용 배너 광고 로드 (재시도 로직 포함)
  void loadHomeBannerAd() {
    print('\n[HOME BANNER] 광고 로드 시도 #${_retryAttempts['homeBanner']! + 1}');
    
    // 기존 광고 정리
    if (_homeBannerAd != null) {
      _homeBannerAd!.dispose();
      _homeBannerAd = null;
      _isHomeBannerAdReady = false;
    }
    
    // 타이머 취소
    _homeBannerRetryTimer?.cancel();
    
    _homeBannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: _adaptiveBannerSize ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _isHomeBannerAdReady = true;
          _retryAttempts['homeBanner'] = 0;
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          
          ad.dispose();
          _isHomeBannerAdReady = false;
          _homeBannerAd = null;
          
          // 재시도 로직
          _handleBannerLoadFailure('homeBanner', error);
        },
        onAdOpened: (Ad ad) {},
        onAdClosed: (Ad ad) {},
        onAdImpression: (Ad ad) {},
      ),
    );
    _homeBannerAd!.load();
  }

  // 편집 화면용 배너 광고 로드
  void loadEditorBannerAd() {
    print('\n[EDITOR BANNER] 광고 로드 시도 #${_retryAttempts['editorBanner']! + 1}');
    
    if (_editorBannerAd != null) {
      _editorBannerAd!.dispose();
      _editorBannerAd = null;
      _isEditorBannerAdReady = false;
    }
    
    _editorBannerRetryTimer?.cancel();
    
    _editorBannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: _adaptiveBannerSize ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _isEditorBannerAdReady = true;
          _retryAttempts['editorBanner'] = 0;
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          
          ad.dispose();
          _isEditorBannerAdReady = false;
          _editorBannerAd = null;
          
          _handleBannerLoadFailure('editorBanner', error);
        },
        onAdOpened: (Ad ad) {},
        onAdClosed: (Ad ad) {},
        onAdImpression: (Ad ad) {},
      ),
    );
    _editorBannerAd!.load();
  }

  // 배너 광고 로드 실패 처리
  void _handleBannerLoadFailure(String adType, LoadAdError error) {
    _retryAttempts[adType] = (_retryAttempts[adType] ?? 0) + 1;
    
    // 에러 코드별 처리
    bool shouldRetry = true;
    int retryDelay = _calculateRetryDelay(_retryAttempts[adType]!);
    
    // 에러 코드 3: No Fill - 더 긴 대기 시간
    if (error.code == 3) {
      retryDelay = retryDelay * 2; // No Fill은 더 긴 대기
    }
    
    // 최대 재시도 횟수 체크
    if (_retryAttempts[adType]! >= _maxRetryAttempts) {
      _retryAttempts[adType] = 0;
      shouldRetry = false;
    }
    
    if (shouldRetry) {
      
      if (adType == 'homeBanner') {
        _homeBannerRetryTimer?.cancel();
        _homeBannerRetryTimer = Timer(Duration(seconds: retryDelay), loadHomeBannerAd);
      } else if (adType == 'editorBanner') {
        _editorBannerRetryTimer?.cancel();
        _editorBannerRetryTimer = Timer(Duration(seconds: retryDelay), loadEditorBannerAd);
      }
    }
  }

  // 전면 광고 로드 (개선된 버전)
  void loadInterstitialAd() {
    // 이미 로드 중이면 중복 로드 방지
    if (_isLoadingInterstitialAd) {
      return;
    }
    
    // 이미 준비된 광고가 있으면 로드하지 않음
    if (_isInterstitialAdReady && _interstitialAd != null) {
      return;
    }
    
    _isLoadingInterstitialAd = true;
    print('\n[INTERSTITIAL] 광고 로드 시작 #${_retryAttempts['interstitial']! + 1}');
    print('[INTERSTITIAL] 광고 ID: $interstitialAdUnitId');
    
    // 기존 광고 정리
    if (_interstitialAd != null) {
      _interstitialAd!.dispose();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
    }
    
    _interstitialRetryTimer?.cancel();
    _interstitialLoadTimeoutTimer?.cancel();
    
    // 타임아웃 설정 (30초)
    _interstitialLoadTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_isLoadingInterstitialAd) {
        _isLoadingInterstitialAd = false;
        // 타임아웃 시 재시도
        _retryAttempts['interstitial'] = (_retryAttempts['interstitial'] ?? 0) + 1;
        _interstitialRetryTimer?.cancel();
        _interstitialRetryTimer = Timer(const Duration(seconds: 5), loadInterstitialAd);
      }
    });
    
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialLoadTimeoutTimer?.cancel();
          _isLoadingInterstitialAd = false;
          
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _retryAttempts['interstitial'] = 0;
          
          // 전면 광고 리스너 설정
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (InterstitialAd ad) {},
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _interstitialAd = null;
              
              // 미리 로드한 광고를 메인으로 이동
              if (_isPreloadedInterstitialReady && _preloadedInterstitialAd != null) {
                _interstitialAd = _preloadedInterstitialAd;
                _isInterstitialAdReady = true;
                _preloadedInterstitialAd = null;
                _isPreloadedInterstitialReady = false;
                
                // 새로운 광고 미리 로드
                _preloadNextInterstitialAd();
              } else {
                // 다음 광고 로드
                Future.delayed(const Duration(seconds: 1), () {
                  loadInterstitialAd();
                });
              }
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _interstitialAd = null;
              Future.delayed(const Duration(seconds: 1), () {
                loadInterstitialAd();
              });
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialLoadTimeoutTimer?.cancel();
          _isLoadingInterstitialAd = false;
          
          
          _isInterstitialAdReady = false;
          _interstitialAd = null;
          
          _handleInterstitialLoadFailure(error);
        },
      ),
    );
  }
  
  // 전면 광고 미리 로드 (백그라운드)
  void _preloadNextInterstitialAd() {
    if (_isLoadingPreloadedAd) {
      return;
    }
    
    if (_isPreloadedInterstitialReady && _preloadedInterstitialAd != null) {
      return;
    }
    
    _isLoadingPreloadedAd = true;
    print('[PRELOAD] 다음 전면 광고 미리 로드 시작...');
    
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isLoadingPreloadedAd = false;
          _preloadedInterstitialAd = ad;
          _isPreloadedInterstitialReady = true;
          
          // 미리 로드한 광고 리스너 설정
          _preloadedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _isPreloadedInterstitialReady = false;
              _preloadedInterstitialAd = null;
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              _isPreloadedInterstitialReady = false;
              _preloadedInterstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoadingPreloadedAd = false;
          _isPreloadedInterstitialReady = false;
          _preloadedInterstitialAd = null;
        },
      ),
    );
  }

  // 전면 광고 로드 실패 처리
  void _handleInterstitialLoadFailure(LoadAdError error) {
    _retryAttempts['interstitial'] = (_retryAttempts['interstitial'] ?? 0) + 1;
    
    bool shouldRetry = true;
    int retryDelay = _calculateRetryDelay(_retryAttempts['interstitial']!);
    
    if (error.code == 3) {
      retryDelay = retryDelay * 2;
    }
    
    if (_retryAttempts['interstitial']! >= _maxRetryAttempts) {
      _retryAttempts['interstitial'] = 0;
      retryDelay = 30; // 30초 후 리셋
    }
    
    if (shouldRetry) {
      _interstitialRetryTimer?.cancel();
      _interstitialRetryTimer = Timer(Duration(seconds: retryDelay), loadInterstitialAd);
    }
  }

  // 재시도 지연 시간 계산 (지수 백오프)
  int _calculateRetryDelay(int attemptNumber) {
    // 2^attemptNumber * initialDelay (최대 32초)
    return min(_initialRetryDelay * pow(2, attemptNumber - 1).toInt(), 32);
  }

  // 전면 광고 표시 (개선된 버전)
  Future<bool> showInterstitialAd() async {
    print('\n===== [INTERSTITIAL] 광고 표시 시도 =====');
    print('[메인 광고] 준비: $_isInterstitialAdReady');
    print('[미리 로드] 준비: $_isPreloadedInterstitialReady');
    print('[로드 중] 메인: $_isLoadingInterstitialAd, 미리로드: $_isLoadingPreloadedAd');
    
    // 메인 광고 우선, 없으면 미리 로드한 광고 사용
    InterstitialAd? adToShow = _interstitialAd ?? _preloadedInterstitialAd;
    
    if (adToShow != null) {
      try {
        print('[INTERSTITIAL] 광고 show() 호출');
        await adToShow.show();
        
        // 사용한 광고 플래그 업데이트
        if (adToShow == _interstitialAd) {
          _isInterstitialAdReady = false;
          _interstitialAd = null;
        } else {
          _isPreloadedInterstitialReady = false;
          _preloadedInterstitialAd = null;
        }
        
        print('[INTERSTITIAL] ✅ 광고 표시 성공!');
        return true;
      } catch (e) {
        return false;
      }
    } else {
      print('[INTERSTITIAL] ⚠️ 표시할 광고가 없습니다.');
      print('[INTERSTITIAL] 재시도 횟수: ${_retryAttempts['interstitial']}');
      
      // 광고가 없고 로드 중도 아니면 즉시 로드 시도
      if (!_isLoadingInterstitialAd && !_isLoadingPreloadedAd) {
        print('[INTERSTITIAL] 즉시 새 광고 로드 시작');
        loadInterstitialAd();
        _preloadNextInterstitialAd();
      }
      return false;
    }
  }

  // 홈 화면용 배너 광고 위젯 반환
  Widget? getHomeBannerAdWidget() {
    if (_isHomeBannerAdReady && _homeBannerAd != null) {
      try {
        return Container(
          alignment: Alignment.center,
          width: _homeBannerAd!.size.width.toDouble(),
          height: _homeBannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _homeBannerAd!),
        );
      } catch (e) {
        _isHomeBannerAdReady = false;
        _homeBannerAd = null;
        loadHomeBannerAd(); // 재로드
        return null;
      }
    }
    
    // 광고가 없으면 재로드 시도
    if (!_isHomeBannerAdReady && _retryAttempts['homeBanner'] == 0) {
      loadHomeBannerAd();
    }
    return null;
  }

  // 편집 화면용 배너 광고 위젯 반환
  Widget? getEditorBannerAdWidget() {
    if (_isEditorBannerAdReady && _editorBannerAd != null) {
      try {
        return Container(
          alignment: Alignment.center,
          width: _editorBannerAd!.size.width.toDouble(),
          height: _editorBannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _editorBannerAd!),
        );
      } catch (e) {
        _isEditorBannerAdReady = false;
        _editorBannerAd = null;
        loadEditorBannerAd(); // 재로드
        return null;
      }
    }
    
    // 광고가 없으면 재로드 시도
    if (!_isEditorBannerAdReady && _retryAttempts['editorBanner'] == 0) {
      loadEditorBannerAd();
    }
    return null;
  }


  // 리소스 정리
  void dispose() {
    _homeBannerRetryTimer?.cancel();
    _editorBannerRetryTimer?.cancel();
    _interstitialRetryTimer?.cancel();
    _interstitialAutoLoadTimer?.cancel();
    _interstitialLoadTimeoutTimer?.cancel();
    
    _homeBannerAd?.dispose();
    _editorBannerAd?.dispose();
    _interstitialAd?.dispose();
    _preloadedInterstitialAd?.dispose();
  }
}