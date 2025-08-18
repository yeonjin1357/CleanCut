# CleanCut - AI 배경 제거 앱

Flutter로 개발된 크로스플랫폼 이미지 배경 제거 애플리케이션입니다. BiRefNet-dynamic 모델을 사용하여 높은 품질의 누끼따기를 제공합니다.

## 🎯 주요 기능

- 갤러리 또는 카메라에서 이미지 선택
- AI 기반 정확한 배경 제거
- 투명 PNG 형식으로 저장
- 처리된 이미지 공유
- iOS/Android 지원

## 🚀 시작하기

### Flutter 앱 실행

1. Flutter 의존성 설치:
```bash
cd cleancut
flutter pub get
```

2. 앱 실행:
```bash
flutter run
```

### Python 서버 설정 (API 방식)

1. Python 의존성 설치:
```bash
pip install -r requirements.txt
```

2. 서버 실행 (2가지 옵션):

**옵션 1: 실제 BiRefNet 모델 사용 (GPU 권장)**
```bash
python server_birefnet.py
# 또는
uvicorn server_birefnet:app --reload --host 0.0.0.0 --port 8000
```

**옵션 2: 테스트용 서버 (모델 없이)**
```bash
python server_example.py
```

서버는 http://localhost:8000 에서 실행됩니다.
API 문서는 http://localhost:8000/docs 에서 확인 가능합니다.

## 📁 프로젝트 구조

```
cleancut/
├── cleancut/              # Flutter 앱
│   ├── lib/
│   │   ├── screens/       # 화면 컴포넌트
│   │   ├── services/      # API 서비스
│   │   ├── providers/     # 상태 관리
│   │   └── widgets/       # 재사용 위젯
│   └── pubspec.yaml
├── server_example.py      # Python FastAPI 서버
├── requirements.txt       # Python 의존성
└── README.md
```

## 🔧 구현 방식

### 1. API 서버 방식 (권장)
- Python FastAPI 서버에서 BiRefNet 모델 실행
- Flutter 앱에서 API 호출
- 장점: 빠른 처리, 작은 앱 크기
- 단점: 인터넷 연결 필요, 서버 비용

### 2. On-Device 방식
- TensorFlow Lite 또는 ONNX Runtime 사용
- 모델을 앱에 포함
- 장점: 오프라인 작동, 프라이버시
- 단점: 큰 앱 크기, 느린 처리

## 📱 스크린샷

- 홈 화면: 이미지 선택
- 처리 중: 로딩 오버레이
- 결과 화면: 배경 제거된 이미지

## 🛠️ 개발 환경

- Flutter SDK: 3.0+
- Dart: 3.0+
- Python: 3.8+
- iOS: 12.0+
- Android: API 21+

## 📝 라이선스

BiRefNet-dynamic 모델은 MIT 라이선스로 상업적 사용이 가능합니다.

## 🔗 참고 자료

- [BiRefNet GitHub](https://github.com/ZhengPeng7/BiRefNet)
- [Flutter Documentation](https://flutter.dev/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

## 📚 문서

- [테스트 가이드](TEST_GUIDE.md) - 로컬 테스트 방법
- [배포 가이드](DEPLOYMENT_GUIDE.md) - 서버 및 앱 배포 방법
- [프로젝트 현황](CLAUDE.md) - 개발 진행 상황

## 🚧 추가 개발 사항

- [x] 실제 BiRefNet 모델 통합 (`server_birefnet.py`)
- [x] API 서버 구현
- [x] Hugging Face Spaces 배포 준비
- [ ] 배치 처리 기능
- [ ] 배경 교체 기능
- [ ] 엣지 다듬기 도구
- [ ] 히스토리 관리
