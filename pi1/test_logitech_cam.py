# test_logitech_cam.py
import cv2

CAM_INDEX = 4  # /dev/video4 = Logitech

cam = cv2.VideoCapture(CAM_INDEX)

if not cam.isOpened():
    print("❌ Failed to open Logitech camera (/dev/video4)")
    exit(1)

ret, frame = cam.read()
cam.release()

if not ret:
    print("❌ Logitech camera opened, but failed to capture frame.")
    exit(1)

print("✅ Logitech camera is working and frame captured successfully.")

# Optional: save test image to verify visually
cv2.imwrite("logitech_test.jpg", frame)
print("🖼️ Saved captured image to logitech_test.jpg")
