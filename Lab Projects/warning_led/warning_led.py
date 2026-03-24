from ultralytics import YOLO
import RPi.GPIO as GPIO
import cv2
import torch
import time
import datetime

# color
GREEN = (0, 255, 0)
WHITE = (255, 255, 255)
RED = (0, 0, 255)
BLACK = (0, 0, 0)

# CAM size & danger zone
CAM_WIDTH = 640
CAM_HEIGHT = 480
DANGER_X = CAM_WIDTH / 2
danger = 0

# Check for CUDA device and set it
device = 'cuda' if torch.cuda.is_available() else 'cpu'
print('Using device: ' + device)

model = YOLO('yolov8n.pt').to(device)

cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAM_WIDTH)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAM_WIDTH)

CONFIDENCE_THRESHOLD = 0.6

led_pin = 40
led_val = 0

# Pin Setup
GPIO.setmode(GPIO.BOARD) # BOARD pin-numbering scheme
GPIO.setup(led_pin, GPIO.OUT) # LED pin set as output
GPIO.output(led_pin, GPIO.LOW)

while True:
    start = datetime.datetime.now()

    ret, frame = cap.read()
    if not ret:
        print('Cam Error')
        break

    detection = model(frame)[0] 

    # display Danger zone
    cv2.line(frame, (int(DANGER_X), 0), (int(DANGER_X), CAM_HEIGHT), RED, 2)
    cv2.putText(frame, "DANGER", (int(CAM_WIDTH / 4 * 3) - 10, 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5, RED, 2)

    if led_val != 1:
        GPIO.output(led_pin, GPIO.LOW)
        
    for data in detection.boxes.data.tolist(): # data : [xmin, ymin, xmax, ymax, confidence_score, class_id]
        confidence = float(data[4])
        if confidence < CONFIDENCE_THRESHOLD:
            continue
            
        xmin, ymin, xmax, ymax = int(data[0]), int(data[1]), int(data[2]), int(data[3])
        label = int(data[5])

        # detect person
        if label == 0:
            # detect person in danger zone
            if (xmin > DANGER_X) or (xmax > DANGER_X):
                danger = 1
                cv2.rectangle(frame, (xmin, ymin), (xmax, ymax), RED, 2)
                cv2.putText(frame, 'Danger !', (xmin, ymin), cv2.FONT_ITALIC, 1, RED, 2)
                led_val = 1
            else: 
                cv2.rectangle(frame, (xmin, ymin), (xmax, ymax), GREEN, 2)
                led_val = 0
        elif label != 0:
            led_val = 0

    if led_val == 1: 
        GPIO.output(led_pin, GPIO.HIGH)
    else:
        GPIO.output(led_pin, GPIO.LOW)

    end = datetime.datetime.now()

    total = (end - start).total_seconds()
    fps = f'FPS: {1 / total:.2f}'
    cv2.putText(frame, fps, (10, 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5, BLACK, 2)

    cv2.imshow('frame', frame)

    if cv2.waitKey(1) == ord('q'):
        break

GPIO.cleanup() # cleanup all GPIO
cap.release()
cv2.destroyAllWindows()