# /gel/main.py - Production Ready Guard-e-Loo Capture System
import cv2
import os
import json
import time
import platform
import numpy as np
from cryptography.hazmat.primitives import serialization, hashes, padding as sym_padding
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend

# === STEP 1: Load RSA public key (Police Scotland) ===
KEY_FILE = "./police_key.key"
ENCRYPTED_OUTPUT = "./capture_encrypted.bin"
NON_ENCRYPTED_PREVIEW = "./capture_preview.jpg"
if not os.path.exists(KEY_FILE):
    raise FileNotFoundError(f"❌ Missing public key at: {KEY_FILE}")

with open(KEY_FILE, "rb") as f:
    public_key = serialization.load_pem_public_key(f.read())

# === STEP 2: Capture one frame from the camera ===
cam = cv2.VideoCapture(0)
if not cam.isOpened():
    raise RuntimeError("❌ Could not open camera. Check /dev/video0 mapping!")

ret, frame = cam.read()
cam.release()

if not ret:
    raise RuntimeError("❌ Failed to capture image from camera.")

print("✅ Captured frame from camera")

# === STEP 3: Convert image to JPEG bytes ===
_, buffer = cv2.imencode('.jpg', frame)
image_bytes = buffer.tobytes()
print(f"✅ Converted image to JPEG bytes ({len(image_bytes)} bytes)")
with open("./capture.jpg", "wb") as f:
    f.write(image_bytes)
print("✅ Wrote /gel/capture.jpg for reference")
# === STEP 4: Create forensic metadata ===
metadata = {
    "timestamp": time.time(),
    "timestamp_iso": time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime()),
    "device_id": "guard-e-loo-001",  # Could be MAC address or serial number
    "system_info": {
        "platform": platform.platform(),
        "node": platform.node(),
        "python_version": platform.python_version()
    },
    "image_info": {
        "original_size": len(image_bytes),
        "format": "JPEG",
        "capture_method": "opencv_camera"
    },
    "encryption_info": {
        "method": "hybrid_rsa_aes",
        "rsa_key_size": 2048,
        "aes_key_size": 256,
        "aes_mode": "CBC"
    }
}

print(f"✅ Created forensic metadata")

# === STEP 5: Hybrid Encryption (Production Ready) ===
# Generate random AES key and IV
aes_key = os.urandom(32)  # 256-bit AES key
aes_iv = os.urandom(16)   # 128-bit IV for CBC mode

print(f"✅ Generated AES key ({len(aes_key)} bytes) and IV ({len(aes_iv)} bytes)")

# Create payload with metadata and image
payload = {
    "metadata": metadata,
    "image_data": image_bytes.hex()  # Convert to hex string for JSON serialization
}
payload_json = json.dumps(payload).encode('utf-8')

print(f"✅ Created payload with metadata ({len(payload_json)} bytes)")

# Encrypt payload with AES
# Add PKCS7 padding
padder = sym_padding.PKCS7(128).padder()
padded_payload = padder.update(payload_json) + padder.finalize()

cipher = Cipher(algorithms.AES(aes_key), modes.CBC(aes_iv), backend=default_backend())
encryptor = cipher.encryptor()
encrypted_payload = encryptor.update(padded_payload) + encryptor.finalize()

print(f"✅ Encrypted payload with AES ({len(encrypted_payload)} bytes)")

# Encrypt AES key with RSA
encrypted_aes_key = public_key.encrypt(
    aes_key,
    padding.OAEP(
        mgf=padding.MGF1(algorithm=hashes.SHA256()),
        algorithm=hashes.SHA256(),
        label=None
    )
)

print(f"✅ Encrypted AES key with RSA ({len(encrypted_aes_key)} bytes)")

# === STEP 6: Create encrypted capture file ===
# File format: [encrypted_aes_key (256 bytes)] + [aes_iv (16 bytes)] + [encrypted_payload]
capture_data = encrypted_aes_key + aes_iv + encrypted_payload

with open("./capture_encrypted.bin", "wb") as f:
    f.write(capture_data)

print(f"🔒 Production encrypted capture written to /gel/capture_encrypted.bin")
print(f"   Total size: {len(capture_data)} bytes")
print(f"   - Encrypted AES key: {len(encrypted_aes_key)} bytes")
print(f"   - AES IV: {len(aes_iv)} bytes")
print(f"   - Encrypted payload: {len(encrypted_payload)} bytes")

# === STEP 7: Save unencrypted reference files ===
with open("./capture_metadata.json", "w") as f:
    json.dump(metadata, f, indent=2)

print("✅ Saved metadata reference to /gel/capture_metadata.json")
print("🔐 Full image + metadata encrypted and ready for police decryption!")
