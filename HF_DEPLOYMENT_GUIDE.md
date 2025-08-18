# Hugging Face Spaces 배포 가이드

## 📌 배포 단계별 가이드

### 1단계: Hugging Face Space 생성

1. [Hugging Face](https://huggingface.co) 로그인
2. 우측 상단 프로필 → "New Space" 클릭
3. 설정:
   - **Space name**: `cleancut-api` (원하는 이름)
   - **Select SDK**: Gradio
   - **Select hardware**: CPU basic (무료) 또는 T4 small (GPU, 유료)
   - **Visibility**: Public
4. "Create Space" 클릭

### 2단계: 파일 업로드

Space가 생성되면 파일을 업로드해야 합니다:

#### 방법 1: 웹 인터페이스 사용
1. Space 페이지에서 "Files" 탭 클릭
2. "Add file" → "Upload files" 클릭
3. 다음 파일들 업로드:
   - `app.py`
   - `server_birefnet.py`
   - `requirements.txt`
   - `README_HF.md` (README.md로 이름 변경)

#### 방법 2: Git 사용 (추천)
```bash
# Space 클론
git clone https://huggingface.co/spaces/[your-username]/cleancut-api

# 파일 복사
cd cleancut-api
cp C:\yeonjin\cleancut\app.py .
cp C:\yeonjin\cleancut\server_birefnet.py .
cp C:\yeonjin\cleancut\requirements.txt .
cp C:\yeonjin\cleancut\README_HF.md README.md

# Git 커밋 및 푸시
git add .
git commit -m "Initial deployment"
git push
```

### 3단계: 하드웨어 설정 (중요!)

BiRefNet 모델은 GPU를 권장합니다:

1. Space 설정 페이지로 이동
2. "Settings" 탭 클릭
3. Hardware 섹션에서:
   - **무료 옵션**: CPU basic (느림, 테스트용)
   - **유료 옵션**: T4 small ($0.60/시간) - 권장
   - **프로 옵션**: A10G small ($1.05/시간) - 빠름

### 4단계: 환경 변수 설정 (선택사항)

Settings → "Repository secrets"에서 추가:
- `MAX_IMAGE_SIZE`: 2048 (이미지 최대 크기)
- `ENABLE_CACHE`: true (캐싱 활성화)

### 5단계: 빌드 및 실행

1. 파일 업로드 후 자동으로 빌드 시작
2. "Building" 상태 확인 (5-10분 소요)
3. 빌드 완료 후 "Running" 상태 확인

### 6단계: Flutter 앱 연동

`lib/services/api_service.dart` 파일 수정:

```dart
class ApiService {
  // Hugging Face Space URL로 변경
  static const String baseUrl = 'https://[your-username]-cleancut-api.hf.space';
  
  // 나머지 코드는 동일
}
```

## 🔧 트러블슈팅

### 문제 1: 메모리 부족
- **해결**: T4 GPU로 업그레이드 또는 이미지 크기 제한

### 문제 2: 빌드 실패
- **해결**: requirements.txt 버전 확인
- torch 버전과 CUDA 호환성 체크

### 문제 3: 느린 처리 속도
- **해결**: GPU 하드웨어로 업그레이드

### 문제 4: CORS 에러
- **해결**: server_birefnet.py의 CORS 설정 확인

## 💰 비용 절약 팁

1. **개발 중**: CPU basic 사용 (무료)
2. **테스트**: T4 GPU를 짧은 시간만 사용
3. **프로덕션**: 
   - 사용량 적음: CPU basic
   - 사용량 많음: T4 GPU + Sleep after 1 hour 설정

## 📊 성능 비교

| 하드웨어 | 처리 시간 (1024px) | 비용 |
|---------|-------------------|------|
| CPU basic | 15-30초 | 무료 |
| T4 small | 2-5초 | $0.60/시간 |
| A10G small | 1-3초 | $1.05/시간 |

## 🚀 배포 후 체크리스트

- [ ] Gradio 인터페이스 작동 확인
- [ ] API 엔드포인트 테스트 (`/remove-background`)
- [ ] Flutter 앱에서 연동 테스트
- [ ] 처리 속도 확인
- [ ] 에러 로그 모니터링

## 📱 Flutter 앱 테스트

```bash
# API URL 변경 후
flutter clean
flutter pub get
flutter run
```

## 🔗 유용한 링크

- [Hugging Face Spaces 문서](https://huggingface.co/docs/hub/spaces)
- [Gradio 문서](https://www.gradio.app/docs)
- [BiRefNet 모델](https://huggingface.co/ZhengPeng7/BiRefNet)

## 📝 참고사항

- Hugging Face Spaces는 48시간 비활성 시 자동 중지됨
- 첫 요청 시 콜드 스타트로 인해 느릴 수 있음
- 무료 플랜은 동시 요청 제한이 있음