"""
BiRefNet을 사용한 실제 배경 제거 API 서버

설치 필요:
pip install fastapi uvicorn python-multipart pillow
pip install torch torchvision transformers
pip install timm einops

실행:
uvicorn server_birefnet:app --reload --host 0.0.0.0 --port 8000
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import io
import torch
import numpy as np
from typing import Tuple
import logging

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="CleanCut API", version="1.0.0")

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 글로벌 모델 변수
model = None
device = None

def load_model():
    """BiRefNet 모델 로드"""
    global model, device
    
    try:
        # GPU 사용 가능 여부 확인
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        logger.info(f"Using device: {device}")
        
        # Hugging Face에서 BiRefNet 모델 로드
        from transformers import AutoModelForImageSegmentation, AutoProcessor
        
        model_name = "ZhengPeng7/BiRefNet"
        logger.info(f"Loading model: {model_name}")
        
        # 모델과 프로세서 로드
        model = AutoModelForImageSegmentation.from_pretrained(
            model_name,
            trust_remote_code=True
        )
        model = model.to(device)
        model.eval()
        
        logger.info("Model loaded successfully")
        return True
        
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        logger.info("Using fallback mode (returning original image)")
        return False

def process_image(image: Image.Image) -> Image.Image:
    """
    BiRefNet을 사용해 배경 제거
    
    Args:
        image: PIL Image 객체
        
    Returns:
        배경이 제거된 RGBA PIL Image
    """
    try:
        if model is None:
            logger.warning("Model not loaded, returning original image with alpha channel")
            return image.convert("RGBA")
        
        # 이미지 전처리
        original_size = image.size
        
        # 모델 입력 크기로 리사이즈 (BiRefNet은 다양한 크기 지원)
        # 일반적으로 1024x1024가 좋은 성능을 보임
        input_size = (1024, 1024)
        image_resized = image.resize(input_size, Image.Resampling.LANCZOS)
        
        # NumPy 배열로 변환
        image_np = np.array(image_resized)
        
        # 정규화 (0-1 범위)
        if image_np.max() > 1:
            image_np = image_np / 255.0
        
        # 텐서로 변환 (batch_size, channels, height, width)
        image_tensor = torch.from_numpy(image_np).float()
        if len(image_tensor.shape) == 3:
            image_tensor = image_tensor.permute(2, 0, 1)  # HWC -> CHW
        image_tensor = image_tensor.unsqueeze(0)  # 배치 차원 추가
        image_tensor = image_tensor.to(device)
        
        # 모델 추론 - BiRefNet의 predict 메서드 사용
        with torch.no_grad():
            # BiRefNet은 PIL Image를 직접 받음
            try:
                # predict 메서드가 있는 경우
                if hasattr(model, 'predict'):
                    mask = model.predict(image)
                    # mask가 PIL Image인 경우 numpy로 변환
                    if isinstance(mask, Image.Image):
                        mask = np.array(mask) / 255.0
                else:
                    # 일반적인 forward 방식
                    output = model(image_tensor)
                    
                    # 출력 형식에 따라 처리
                    if isinstance(output, dict):
                        mask = output.get('logits', output.get('out', output))
                    elif isinstance(output, (list, tuple)):
                        # BiRefNet이 리스트를 반환하는 경우 (multi-scale output)
                        # 마지막 스케일의 출력 사용
                        mask = output[-1] if len(output) > 0 else output[0]
                    else:
                        mask = output
                    
                    # mask가 이미 텐서가 아닌 경우 텐서로 변환
                    if not isinstance(mask, torch.Tensor):
                        if isinstance(mask, list):
                            mask = mask[0] if len(mask) > 0 else mask
                        mask = torch.tensor(mask) if not isinstance(mask, torch.Tensor) else mask
                    
                    # 시그모이드 적용하여 0-1 범위로 변환
                    mask = torch.sigmoid(mask)
                    mask = mask.squeeze().cpu().numpy()
            except Exception as e:
                logger.error(f"Model inference failed: {e}")
                raise
        
        # 마스크를 원본 크기로 리사이즈
        mask_pil = Image.fromarray((mask * 255).astype(np.uint8))
        mask_pil = mask_pil.resize(original_size, Image.Resampling.LANCZOS)
        
        # 원본 이미지를 RGBA로 변환
        image_rgba = image.convert("RGBA")
        
        # 마스크를 알파 채널로 적용
        image_rgba.putalpha(mask_pil)
        
        return image_rgba
        
    except Exception as e:
        logger.error(f"Error processing image: {e}")
        # 에러 발생 시 원본 이미지를 RGBA로 변환하여 반환
        return image.convert("RGBA")

def simple_background_removal(image: Image.Image) -> Image.Image:
    """
    간단한 배경 제거 (폴백 메서드)
    실제 모델이 로드되지 않았을 때 사용
    """
    # 이미지를 RGBA로 변환
    image_rgba = image.convert("RGBA")
    
    # 간단한 임계값 기반 마스크 생성 (데모용)
    # 실제로는 BiRefNet 모델을 사용해야 함
    data = image_rgba.getdata()
    new_data = []
    
    for item in data:
        # 흰색 배경을 투명하게 만들기 (매우 단순한 예제)
        if item[0] > 240 and item[1] > 240 and item[2] > 240:
            new_data.append((item[0], item[1], item[2], 0))
        else:
            new_data.append(item)
    
    image_rgba.putdata(new_data)
    return image_rgba

@app.on_event("startup")
async def startup_event():
    """서버 시작 시 모델 로드"""
    success = load_model()
    if not success:
        logger.warning("Running in demo mode without BiRefNet model")

@app.get("/")
async def root():
    """API 상태 확인"""
    return {
        "service": "CleanCut Background Removal API",
        "status": "running",
        "model_loaded": model is not None,
        "device": str(device) if device else "cpu"
    }

@app.get("/health")
async def health_check():
    """헬스 체크 엔드포인트"""
    return {
        "status": "healthy",
        "model_loaded": model is not None
    }

@app.post("/remove-background")
async def remove_background(
    file: UploadFile = File(...),
    quality: int = 95
):
    """
    이미지 배경 제거 API
    
    Args:
        file: 업로드된 이미지 파일
        quality: PNG 압축 품질 (1-100, 기본값 95)
        
    Returns:
        배경이 제거된 PNG 이미지
    """
    try:
        # 파일 유효성 검사
        if not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # 이미지 읽기
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # RGB로 변환 (RGBA 이미지 처리를 위해)
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        logger.info(f"Processing image: {file.filename}, size: {image.size}")
        
        # 배경 제거 처리
        if model is not None:
            result = process_image(image)
        else:
            # 모델이 없으면 간단한 폴백 메서드 사용
            result = simple_background_removal(image)
        
        # PNG로 저장
        output = io.BytesIO()
        result.save(output, format="PNG", quality=quality, optimize=True)
        output.seek(0)
        
        return Response(
            content=output.getvalue(),
            media_type="image/png",
            headers={
                "Content-Disposition": f"attachment; filename=cleaned_{file.filename}.png"
            }
        )
        
    except Exception as e:
        logger.error(f"Error processing request: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/remove-background-batch")
async def remove_background_batch(files: list[UploadFile] = File(...)):
    """
    여러 이미지 배경 제거 (배치 처리)
    
    Args:
        files: 업로드된 이미지 파일 리스트
        
    Returns:
        처리 결과 정보
    """
    results = []
    
    for file in files:
        try:
            # 각 파일 처리
            contents = await file.read()
            image = Image.open(io.BytesIO(contents))
            
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # 배경 제거
            if model is not None:
                result = process_image(image)
            else:
                result = simple_background_removal(image)
            
            # 결과 저장
            output = io.BytesIO()
            result.save(output, format="PNG", optimize=True)
            
            results.append({
                "filename": file.filename,
                "status": "success",
                "size": len(output.getvalue())
            })
            
        except Exception as e:
            results.append({
                "filename": file.filename,
                "status": "failed",
                "error": str(e)
            })
    
    return {"results": results}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)