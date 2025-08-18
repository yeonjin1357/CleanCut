"""
BiRefNet을 사용한 배경 제거 API 서버 예제

설치 필요 패키지:
pip install fastapi uvicorn python-multipart pillow torch torchvision transformers

실행:
uvicorn server_example:app --reload --host 0.0.0.0 --port 8000
"""

from fastapi import FastAPI, File, UploadFile
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import io
import torch
from transformers import AutoModelForImageSegmentation, AutoProcessor
import numpy as np

app = FastAPI()

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 모델 로드 (앱 시작 시 한 번만 실행)
print("모델 로딩 중...")
# 실제 BiRefNet 모델 사용 예제
# model_name = "ZhengPeng7/BiRefNet"  # Hugging Face 모델 이름
# processor = AutoProcessor.from_pretrained(model_name)
# model = AutoModelForImageSegmentation.from_pretrained(model_name)

# 임시 테스트용 - 실제로는 위의 BiRefNet 모델을 사용해야 함
model = None
processor = None

def remove_background(image: Image.Image) -> Image.Image:
    """
    이미지에서 배경을 제거하는 함수
    실제 구현 시 BiRefNet 모델을 사용
    """
    if model is None or processor is None:
        # 모델이 로드되지 않은 경우 임시로 원본 반환
        # 실제로는 여기서 BiRefNet으로 처리해야 함
        
        # 임시 구현: 간단한 투명 배경 추가
        image = image.convert("RGBA")
        return image
    
    # BiRefNet을 사용한 실제 구현 예제:
    # inputs = processor(images=image, return_tensors="pt")
    # with torch.no_grad():
    #     outputs = model(**inputs)
    #     mask = outputs.logits.sigmoid() > 0.5
    
    # # 마스크를 이용해 배경 제거
    # mask = mask.squeeze().cpu().numpy()
    # image_array = np.array(image.convert("RGBA"))
    # image_array[:, :, 3] = (mask * 255).astype(np.uint8)
    # result = Image.fromarray(image_array)
    
    # return result
    
    return image

@app.get("/")
async def root():
    return {"message": "CleanCut API Server", "status": "running"}

@app.post("/remove-background")
async def remove_bg(file: UploadFile = File(...)):
    """
    이미지 파일을 받아 배경을 제거한 후 PNG로 반환
    """
    try:
        # 이미지 읽기
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # 배경 제거
        result = remove_background(image)
        
        # 결과를 PNG로 변환
        output = io.BytesIO()
        result.save(output, format="PNG")
        output.seek(0)
        
        return Response(
            content=output.getvalue(),
            media_type="image/png",
            headers={"Content-Disposition": "attachment; filename=result.png"}
        )
    
    except Exception as e:
        return {"error": str(e)}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "model_loaded": model is not None}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)