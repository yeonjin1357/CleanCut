---
title: CleanCut Background Remover
emoji: ✂️
colorFrom: blue
colorTo: purple
sdk: docker
pinned: false
license: mit
models:
  - ZhengPeng7/BiRefNet
---

# CleanCut - AI Background Remover

Professional background removal powered by BiRefNet model.

## Features
- 🚀 High-quality background removal
- 🎨 Preserves fine details (hair, fur, etc.)
- 📱 Mobile app support via API
- 🔥 Fast processing with GPU acceleration

## API Usage

### Endpoint
```
POST https://[your-space-name].hf.space/remove-background
```

### Example (Python)
```python
import requests
from PIL import Image
import io

# Send image
with open('image.jpg', 'rb') as f:
    response = requests.post(
        'https://[your-space-name].hf.space/remove-background',
        files={'file': f}
    )

# Save result
if response.status_code == 200:
    img = Image.open(io.BytesIO(response.content))
    img.save('result.png')
```

### Example (Flutter/Dart)
```dart
import 'package:dio/dio.dart';

final dio = Dio();
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(imagePath),
});

final response = await dio.post(
  'https://[your-space-name].hf.space/remove-background',
  data: formData,
);

if (response.statusCode == 200) {
  // response.data contains the PNG image bytes
}
```

## Model Information
- **Model**: BiRefNet-dynamic
- **License**: MIT
- **Paper**: [BiRefNet: Bilateral Reference Network](https://arxiv.org/abs/2312.00090)

## Development
This is the server component for the CleanCut mobile app.

### Local Setup
```bash
pip install -r requirements.txt
python app.py
```

## Links
- 📱 [Mobile App](#) (Coming soon)
- 💻 [GitHub Repository](#)
- 📄 [Model Card](https://huggingface.co/ZhengPeng7/BiRefNet)