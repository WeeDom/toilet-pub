# test_tablet_stream.py
import cv2

TABLET_STREAM = "http://172.23.190.183:8080/video"  # replace with your actual IP

cap = cv2.VideoCapture(TABLET_STREAM)

if not cap.isOpened():
    print("❌ Could not open tablet stream.")
    exit(1)

print("✅ Tablet stream opened. Capturing frame...")

ret, frame = cap.read()
cap.release()

if not ret:
    print("❌ Failed to capture frame from tablet.")
else:
    cv2.imwrite("tablet_entry.jpg", frame)
    print("📸 Frame saved to tablet_entry.jpg")
