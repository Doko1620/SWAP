import uvicorn
import numpy as np
import tensorflow as tf
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware # Import CORS
from PIL import Image
import io

IM_SIZE = 224
TFLITE_MODEL_PATH = "model.tflite"

app = FastAPI(title="Fashion Classification API")


app.add_middleware(CORSMiddleware, allow_origins=["*"],  allow_credentials=True,allow_methods=["*"],  allow_headers=["*"], )

print("Loading tfLite model and labels")
try:
    with open("labels.txt", "r") as f:
        labels = [line.strip() for line in f.readlines()]
        print(f"Loaded {len(labels)} labels.")

    interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL_PATH)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    print("TFLite model loaded successfully.")
except Exception as e:
    print(f"FATAL ERROR loading model or labels: {e}")
    labels = []
    interpreter = None


def preprocess_image(image_bytes):
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    
    img_resized = img.resize((IM_SIZE, IM_SIZE), Image.BICUBIC) 
    img_array = np.array(img_resized)
    img_array = np.expand_dims(img_array, axis=0) 
    img_processed = tf.keras.applications.efficientnet_v2.preprocess_input(img_array)
    
    return img_processed.astype(np.float32)

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    
    if not interpreter or not labels:
        return {"error": "Model not loaded or labels missing."}

    image_bytes = await file.read()
    
    try:
        img_array = preprocess_image(image_bytes)
    except Exception as e:
        return {"error": f"Failed to preprocess image: {e}"}

    interpreter.set_tensor(input_details[0]['index'], img_array)
    interpreter.invoke()
    pred = interpreter.get_tensor(output_details[0]['index'])
    
    pred_index = int(np.argmax(pred))
    pred_label = labels[pred_index]
    confidence = float(np.max(pred))
    
    return {
        "label": pred_label,
        "confidence": confidence,
        "raw_scores": pred.tolist() 
    }

@app.get("/")
def read_root():
    return {"message": "Fashion API is running!"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)