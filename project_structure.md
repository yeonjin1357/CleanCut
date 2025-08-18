# CleanCut - Flutter 배경 제거 앱 프로젝트 구조

## 📁 프로젝트 구조

```
cleancut/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── editor_screen.dart
│   │   └── gallery_screen.dart
│   ├── services/
│   │   ├── api_service.dart          # API 방식
│   │   ├── ml_service.dart           # On-device 방식
│   │   └── image_processor.dart
│   ├── providers/
│   │   └── app_state.dart
│   ├── widgets/
│   │   ├── image_picker_widget.dart
│   │   ├── loading_overlay.dart
│   │   └── result_viewer.dart
│   └── utils/
│       ├── constants.dart
│       └── image_utils.dart
├── assets/
│   ├── models/                       # On-device 모델 저장
│   └── images/
├── android/
├── ios/
└── pubspec.yaml
```

## 🔧 주요 기능

### 핵심 기능
1. **이미지 선택**: 갤러리/카메라에서 이미지 선택
2. **배경 제거**: BiRefNet-dynamic 모델로 누끼 따기
3. **결과 저장**: PNG 형식으로 투명 배경 저장
4. **공유**: 처리된 이미지 공유

### 추가 기능 (선택)
- 배치 처리
- 배경 교체
- 엣지 다듬기
- 히스토리 관리

## 📦 필요한 패키지

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 핵심 패키지
  image_picker: ^1.0.7
  provider: ^6.1.1
  dio: ^5.4.0                 # API 통신
  path_provider: ^2.1.2
  share_plus: ^7.2.1
  
  # On-device ML (선택)
  tflite_flutter: ^0.10.4     # TensorFlow Lite
  # 또는
  onnxruntime: ^0.5.0         # ONNX Runtime
  
  # UI/UX
  flutter_spinkit: ^5.2.0
  cached_network_image: ^3.3.1
  photo_view: ^0.14.0
```

## 🚀 구현 단계

### Phase 1: 기본 구조 (1주)
- Flutter 프로젝트 생성
- 기본 UI 구현
- 이미지 선택 기능

### Phase 2: ML 통합 (2주)
- API 서버 구축 (Python FastAPI + BiRefNet)
- 또는 모델 변환 (PyTorch → ONNX → TFLite)
- Flutter 연동

### Phase 3: 기능 완성 (1주)
- 결과 저장/공유
- 에러 처리
- UI 개선

### Phase 4: 최적화 (1주)
- 성능 최적화
- 테스트
- 배포 준비

## 💡 구현 팁

### API 서버 구축 (권장)
```python
# Python FastAPI 서버 예제
from fastapi import FastAPI, UploadFile
from birefnet import BiRefNet

app = FastAPI()
model = BiRefNet.from_pretrained("BiRefNet-dynamic")

@app.post("/remove-background")
async def remove_bg(file: UploadFile):
    # 이미지 처리 로직
    result = model.process(file)
    return result
```

### Flutter 클라이언트
```dart
class BackgroundRemovalService {
  final Dio _dio = Dio();
  
  Future<Uint8List> removeBackground(File image) async {
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path),
    });
    
    Response response = await _dio.post(
      'https://your-api.com/remove-background',
      data: formData,
    );
    
    return response.data;
  }
}
```

## 🎯 예상 결과

- **처리 시간**: 
  - API 방식: 2-5초
  - On-device: 5-15초
- **품질**: 상업용 수준의 정확한 누끼
- **앱 크기**:
  - API 방식: 15-20MB
  - On-device: 100-150MB