"""
Gradio 인터페이스가 포함된 Hugging Face Spaces용 앱
FastAPI와 Gradio를 함께 실행
"""

import gradio as gr
from PIL import Image
import numpy as np
import io
from server_birefnet import process_image, simple_background_removal, load_model
import torch

# 모델 로드
print("Loading BiRefNet model...")
model_loaded = load_model()

def remove_background_gradio(input_image):
    """Gradio 인터페이스용 배경 제거 함수"""
    if input_image is None:
        return None
    
    # PIL Image로 변환
    if isinstance(input_image, np.ndarray):
        image = Image.fromarray(input_image)
    else:
        image = input_image
    
    # RGB로 변환
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    # 배경 제거
    try:
        if model_loaded:
            result = process_image(image)
        else:
            result = simple_background_removal(image)
        return result
    except Exception as e:
        print(f"Error: {e}")
        return image.convert("RGBA")

# Gradio 인터페이스 생성
with gr.Blocks(title="CleanCut - AI 배경 제거") as demo:
    gr.Markdown(
        """
        # 🎨 CleanCut - AI 배경 제거
        
        BiRefNet 모델을 사용한 고품질 배경 제거 서비스입니다.
        
        ### 사용 방법:
        1. 이미지를 업로드하거나 드래그 앤 드롭하세요
        2. '배경 제거' 버튼을 클릭하세요
        3. 결과 이미지를 다운로드하세요
        
        ### API 엔드포인트:
        - POST `/remove-background` - 프로그래매틱 액세스용
        """
    )
    
    with gr.Row():
        with gr.Column():
            input_image = gr.Image(
                label="원본 이미지",
                type="pil",
                height=400
            )
            process_btn = gr.Button(
                "🚀 배경 제거",
                variant="primary",
                size="lg"
            )
            
        with gr.Column():
            output_image = gr.Image(
                label="결과 이미지",
                type="pil",
                height=400
            )
            download_btn = gr.Button(
                "💾 다운로드",
                variant="secondary",
                size="lg"
            )
    
    # 예제 이미지들 (파일이 있을 때만 활성화)
    # gr.Examples(
    #     examples=[
    #         ["examples/person.jpg"],
    #         ["examples/product.jpg"],
    #         ["examples/pet.jpg"],
    #     ],
    #     inputs=input_image,
    #     label="예제 이미지"
    # )
    
    # 이벤트 연결
    process_btn.click(
        fn=remove_background_gradio,
        inputs=input_image,
        outputs=output_image
    )
    
    # Footer
    gr.Markdown(
        """
        ---
        💡 **Tips**: 
        - 최상의 결과를 위해 고해상도 이미지를 사용하세요
        - 복잡한 배경의 경우 처리 시간이 더 걸릴 수 있습니다
        
        🔗 [GitHub](https://github.com/yourusername/cleancut) | 
        📱 [Flutter App](https://play.google.com/store/apps/details?id=com.cleancut)
        """
    )

# FastAPI 앱도 함께 실행 (선택사항)
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from threading import Thread

# FastAPI 설정
from server_birefnet import app as fastapi_app

def run_fastapi():
    """FastAPI 서버를 별도 스레드에서 실행"""
    uvicorn.run(fastapi_app, host="0.0.0.0", port=7861)

# FastAPI를 백그라운드에서 실행
# api_thread = Thread(target=run_fastapi, daemon=True)
# api_thread.start()

if __name__ == "__main__":
    # Gradio 앱 실행
    demo.launch(
        server_name="0.0.0.0",
        server_port=7860,
        share=False
    )