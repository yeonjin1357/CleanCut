import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/app_theme.dart';
import '../services/ad_service.dart';

class LoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final double? progress;
  final String? stage;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.progress,
    this.stage,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  DateTime? _startTime;
  String _elapsedTime = '';

  @override
  void initState() {
    super.initState();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
          });
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _loadBannerAd(); // 로딩 시작 시 광고 로드
      _startTime = DateTime.now();
      _updateElapsedTime();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _bannerAd?.dispose(); // 로딩 종료 시 광고 정리
      setState(() {
        _isAdLoaded = false;
        _bannerAd = null;
        _startTime = null;
        _elapsedTime = '';
      });
    }
  }
  
  void _updateElapsedTime() {
    if (!widget.isLoading || _startTime == null) return;
    
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !widget.isLoading) return;
      
      final elapsed = DateTime.now().difference(_startTime!);
      final seconds = elapsed.inSeconds;
      setState(() {
        if (seconds < 60) {
          _elapsedTime = '${seconds}초';
        } else {
          final minutes = seconds ~/ 60;
          final remainingSeconds = seconds % 60;
          _elapsedTime = '${minutes}분 ${remainingSeconds}초';
        }
      });
      _updateElapsedTime();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
  
  String _getStageMessage() {
    switch (widget.stage) {
      case 'uploading':
        return '이미지를 업로드하고 있어요';
      case 'processing':
        return '꼼꼼하게 배경을 제거하고 있어요';
      case 'downloading':
        return '거의 완료되었어요';
      case 'completed':
        return '완료!';
      default:
        return widget.message ?? '꼼꼼하게 배경을 제거하고 있어요';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitFadingCircle(color: AppTheme.primaryColor, size: 60),
                  const SizedBox(height: 30),
                  Text(
                    _getStageMessage(),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _startTime != null && DateTime.now().difference(_startTime!).inSeconds > 30
                        ? '처리에 시간이 걸릴 수 있어요 ($_elapsedTime)'
                        : '잠시만 기다려주세요',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (_startTime != null && DateTime.now().difference(_startTime!).inSeconds > 60)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '무료 서버는 처리 속도가 느릴 수 있어요',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  // 진행바 추가
                  Container(
                    width: 200,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: widget.progress ?? 0.0,
                            minHeight: 6,
                            backgroundColor: AppTheme.primaryColor
                                .withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${((widget.progress ?? 0.0) * 100).toInt()}%',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 배너 광고 추가
                  if (_isAdLoaded && _bannerAd != null)
                    Container(
                      alignment: Alignment.center,
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
