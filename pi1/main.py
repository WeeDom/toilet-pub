#! /usr/bin/env python

# main.py
import time
import cv2
from datetime import datetime
from camera_stream import CameraStream

TABLET_URL = "http://172.23.190.183:8080/video"
MOTION_THRESHOLD = 100000  # Adjust to taste
CHECK_INTERVAL = 0.5         # Seconds between frame checks
SLEEP_AFTER_MOTION = 120   # 2 minutes in seconds

def detect_motion(prev, curr):
    g1 = cv2.cvtColor(prev, cv2.COLOR_BGR2GRAY)
    g2 = cv2.cvtColor(curr, cv2.COLOR_BGR2GRAY)
    b1 = cv2.GaussianBlur(g1, (21, 21), 0)
    b2 = cv2.GaussianBlur(g2, (21, 21), 0)
    delta = cv2.absdiff(b1, b2)
    thresh = cv2.threshold(delta, 25, 255, cv2.THRESH_BINARY)[1]
    motion_score = thresh.sum()
    return motion_score > MOTION_THRESHOLD

def main():
    motion_flag = False
    tablet_cam = CameraStream(TABLET_URL, label="entry")

    print("📡 Starting motion monitoring using tablet cam...")

    prev_frame = None

    while True:
        if motion_flag:
            print("⏸️ Motion detected, stream closed. Waiting 2 minutes...")
            time.sleep(SLEEP_AFTER_MOTION)
            motion_flag = False
            tablet_cam = CameraStream(TABLET_URL, label="entry")
            prev_frame = None
            continue

        ret, frame = tablet_cam.read()
        if not ret:
            print("⚠️ Could not read from tablet cam. Retrying...")
            time.sleep(1)
            continue

        if prev_frame is None:
            prev_frame = frame
            time.sleep(CHECK_INTERVAL)
            continue

        if detect_motion(prev_frame, frame):
            print(f"🚨 Motion detected at {datetime.now().strftime('%H:%M:%S')}")
            motion_flag = True
            tablet_cam.release()
        else:
            print(f"✅ No motion. [{datetime.now().strftime('%H:%M:%S')}]")

        prev_frame = frame
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()
