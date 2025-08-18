# Python 설치 가이드 (Windows)

## 1. Python 설치

### 옵션 A: 공식 웹사이트에서 설치 (권장)

1. **Python 다운로드**
   - https://www.python.org/downloads/ 접속
   - "Download Python 3.11.x" 버튼 클릭 (3.10 이상 권장)

2. **설치 시 중요 설정**
   - ✅ **"Add Python to PATH"** 체크박스 반드시 선택!
   - "Install Now" 클릭

3. **설치 확인**
   ```powershell
   # PowerShell 재시작 후
   python --version
   pip --version
   ```

### 옵션 B: Microsoft Store에서 설치

1. **Microsoft Store 열기**
   ```powershell
   # PowerShell에서 실행
   python
   ```
   → Microsoft Store가 자동으로 열림

2. **Python 3.11 설치**
   - "Get" 또는 "설치" 클릭

## 2. 설치 후 패키지 설치

### PowerShell에서 실행
```powershell
# Python 확인
python --version

# pip 업그레이드
python -m pip install --upgrade pip

# 패키지 설치
python -m pip install -r requirements.txt
```

### 만약 여전히 안 된다면
```powershell
# Python 직접 경로 사용
py --version
py -m pip install -r requirements.txt
```

## 3. 가상 환경 사용 (선택사항, 권장)

```powershell
# 가상 환경 생성
python -m venv venv

# 가상 환경 활성화 (Windows PowerShell)
.\venv\Scripts\Activate.ps1

# 권한 오류 시
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 가상 환경 활성화 (Windows CMD)
venv\Scripts\activate.bat

# 패키지 설치
pip install -r requirements.txt
```

## 4. 간단한 서버 테스트

**GPU가 없어도 괜찮습니다!** CPU로도 작동합니다 (조금 느릴 뿐).

```powershell
# 테스트용 서버 실행 (모델 없이)
python server_example.py

# 또는 실제 서버 (CPU 모드)
python server_birefnet.py
```

## 5. 문제 해결

### "pip이 인식되지 않습니다" 오류
```powershell
# Python과 함께 pip 실행
python -m pip install -r requirements.txt

# 또는
py -m pip install -r requirements.txt
```

### "python이 인식되지 않습니다" 오류
1. Python 재설치 (PATH 추가 확인)
2. 시스템 환경 변수 수동 추가:
   - 시작 → "환경 변수" 검색
   - Path에 Python 경로 추가
   - 예: `C:\Users\사용자명\AppData\Local\Programs\Python\Python311`
   - 예: `C:\Users\사용자명\AppData\Local\Programs\Python\Python311\Scripts`

### 패키지 설치가 느린 경우
```powershell
# 국내 미러 사용
python -m pip install -r requirements.txt -i https://pypi.org/simple
```

## 6. 최소 테스트 (GPU 없이)

Python 설치가 어렵다면, 일단 Flutter 앱만 테스트하세요:

1. `server_example.py`를 실행하는 대신
2. Flutter 앱의 `lib/services/api_service.dart`에서 임시로 원본 이미지 반환
3. UI 테스트만 진행

## 💡 빠른 해결책

### 방법 1: Anaconda 설치 (가장 쉬움)
1. https://www.anaconda.com/download 
2. Anaconda 설치 (Python 포함)
3. Anaconda Prompt 실행
4. `pip install -r requirements.txt`

### 방법 2: Google Colab 사용 (설치 불필요)
1. https://colab.research.google.com
2. 새 노트북 생성
3. 코드 붙여넣기 및 실행

### 방법 3: GitHub Codespaces (클라우드 개발)
1. GitHub에 코드 업로드
2. Codespaces에서 개발
3. 자동으로 Python 환경 구성됨