# camera_stream.py
import cv2
from datetime import datetime
import os

class CameraStream:
    def __init__(self, source, label="camera"):
        self.source = source
        self.label = label
        self.cap = cv2.VideoCapture(source)
        self.last_frame = None

    def is_ready(self):
        return self.cap.isOpened()

    def read(self):
    # Discard potentially stale frames
        for _ in range(2):  # Discard first 2 frames to flush buffer
            self.cap.read()

        ret, frame = self.cap.read()
        if ret:
            self.last_frame = frame
        return ret, frame


    def capture(self, output_dir="captures"):
        if not self.is_ready():
            print(f"❌ [{self.label}] not ready.")
            return None
        ret, frame = self.read()
        if not ret:
            print(f"❌ [{self.label}] failed to read frame.")
            return None
        os.makedirs(output_dir, exist_ok=True)
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        path = os.path.join(output_dir, f"{self.label}_{ts}.jpg")
        cv2.imwrite(path, frame)
        print(f"📸 [{self.label}] saved to {path}")
        return path

    def release(self):
        self.cap.release()
