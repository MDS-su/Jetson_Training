from ultralytics import YOLO
from PIL import Image
import cv2
import torch

# Check for CUDA device and set it
device = 'cuda' if torch.cuda.is_available() else 'cpu'
print('Using device: ' + device)

# Load a pretrained YOLOv8n model
model = YOLO('yolov8n.pt').to(device)

source = "0" # camera
#source = "https://media.roboflow.com/notebooks/examples/dog.jpeg" # image file

try:
    # Run inference on the source
    results = model.predict(source, show=True, save=True) # generator of Results objects

except KeyboardInterrupt:
    print("\nExit")