"""
FastAPI 전용 서버 (Gradio 없이)
Hugging Face Spaces에서 API만 제공
"""

import io
import os
from typing import Optional
from PIL import Image
import numpy as np
import torch
from fastapi import FastAPI, UploadFile, Response, HTTPException, File
from fastapi.middleware.cors import CORSMiddleware
from transformers import AutoModelForImageSegmentation, AutoProcessor
import uvicorn
import logging

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# FastAPI 앱 생성
app = FastAPI(title="CleanCut Background Removal API")

# CORS 설정 (모든 origin 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 전역 변수로 모델과 프로세서 저장
model = None
processor = None
device = None

def load_model():
    """BiRefNet 모델 로드"""
    global model, processor, device
    
    try:
        logger.info("Loading BiRefNet model...")
        
        # GPU 사용 가능 여부 확인
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        logger.info(f"Using device: {device}")
        
        # 모델 로드
        model = AutoModelForImageSegmentation.from_pretrained(
            "ZhengPeng7/BiRefNet",
            trust_remote_code=True
        )
        model = model.to(device)
        model.eval()
        
        # 프로세서 로드
        processor = AutoProcessor.from_pretrained(
            "ZhengPeng7/BiRefNet",
            trust_remote_code=True
        )
        
        logger.info("Model loaded successfully!")
        return True
        
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        return False

def simple_background_removal(image: Image.Image) -> Image.Image:
    """간단한 배경 제거 (fallback)"""
    # RGBA로 변환
    if image.mode != 'RGBA':
        image = image.convert('RGBA')
    
    # 간단한 알파 채널 추가
    data = image.getdata()
    new_data = []
    
    for item in data:
        # 흰색 배경을 투명하게 (매우 기본적인 방법)
        if item[0] > 200 and item[1] > 200 and item[2] > 200:
            new_data.append((item[0], item[1], item[2], 0))
        else:
            new_data.append(item)
    
    image.putdata(new_data)
    return image

def process_image(image: Image.Image) -> Image.Image:
    """이미지 배경 제거 처리"""
    if model is None or processor is None:
        logger.warning("Model not loaded, using fallback")
        return simple_background_removal(image)
    
    try:
        # RGB로 변환
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # 이미지 전처리
        inputs = processor(images=image, return_tensors="pt")
        
        # GPU로 이동
        inputs = {k: v.to(device) for k, v in inputs.items()}
        
        # 추론 실행
        with torch.no_grad():
            outputs = model(**inputs)
            
        # 마스크 생성
        predictions = outputs.logits
        mask = torch.nn.functional.interpolate(
            predictions,
            size=image.size[::-1],
            mode='bilinear',
            align_corners=False
        )
        mask = torch.sigmoid(mask)
        mask = mask.squeeze().cpu().numpy()
        
        # 마스크 이진화
        mask = (mask > 0.5).astype(np.uint8) * 255
        
        # RGBA 이미지 생성
        result = Image.new("RGBA", image.size)
        result.paste(image, (0, 0))
        
        # 알파 채널로 마스크 적용
        mask_image = Image.fromarray(mask).convert('L')
        result.putalpha(mask_image)
        
        return result
        
    except Exception as e:
        logger.error(f"Error processing image: {e}")
        return simple_background_removal(image)

# 서버 시작 시 모델 로드
logger.info("Starting server...")
model_loaded = load_model()
if not model_loaded:
    logger.warning("Model loading failed, using fallback mode")

@app.get("/")
async def root():
    """루트 엔드포인트"""
    return {
        "message": "CleanCut API is running",
        "endpoints": {
            "health": "/health",
            "remove_background": "/remove-background"
        }
    }

@app.get("/health")
async def health_check():
    """헬스 체크 엔드포인트"""
    return {
        "status": "healthy",
        "model_loaded": model is not None,
        "device": str(device) if device else "cpu"
    }

@app.post("/remove-background")
async def remove_background(file: UploadFile = File(...)):
    """배경 제거 API 엔드포인트"""
    
    if not file:
        raise HTTPException(status_code=400, detail="No file provided")
    
    # 파일 형식 체크
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        # 이미지 읽기
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        logger.info(f"Processing image: {file.filename}, size: {image.size}")
        
        # 배경 제거 처리
        result = process_image(image)
        
        # PNG 형식으로 저장
        output_buffer = io.BytesIO()
        result.save(output_buffer, format="PNG", optimize=True)
        output_buffer.seek(0)
        
        logger.info(f"Successfully processed image: {file.filename}")
        
        return Response(
            content=output_buffer.getvalue(),
            media_type="image/png",
            headers={"Content-Disposition": f"inline; filename=processed_{file.filename}"}
        )
        
    except Exception as e:
        logger.error(f"Error processing file {file.filename}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Hugging Face Spaces용 설정
if __name__ == "__main__":
    port = int(os.getenv("PORT", 7860))
    uvicorn.run(app, host="0.0.0.0", port=port)