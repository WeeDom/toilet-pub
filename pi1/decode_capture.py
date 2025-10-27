#!/usr/bin/env python3
"""
Guard-e-Loo Production Capture Decoder
Decodes encrypted captures using hybrid RSA+AES encryption
"""

import os
import sys
import json
from datetime import datetime
from cryptography.hazmat.primitives import hashes, serialization, padding as sym_padding
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend

def load_private_key(private_key_path):
    """Load the police private key from PEM file"""
    try:
        with open(private_key_path, 'rb') as key_file:
            private_key = serialization.load_pem_private_key(
                key_file.read(),
                password=None,  # Assuming no password
            )
        print(f"✓ Private key loaded successfully from {private_key_path}")
        return private_key
    except Exception as e:
        print(f"✗ Failed to load private key: {e}")
        return None

def decrypt_capture_file(encrypted_file_path, private_key):
    """Decrypt the capture file using hybrid RSA+AES encryption"""
    try:
        with open(encrypted_file_path, 'rb') as f:
            encrypted_data = f.read()

        print(f"✓ Loaded encrypted file: {len(encrypted_data)} bytes")

        # Parse file format: [encrypted_aes_key (256 bytes)] + [aes_iv (16 bytes)] + [encrypted_payload]
        if len(encrypted_data) < 272:  # 256 + 16 minimum
            raise ValueError("File too small for hybrid encryption format")

        encrypted_aes_key = encrypted_data[:256]  # RSA-2048 encrypted AES key
        aes_iv = encrypted_data[256:272]  # 16-byte AES IV
        encrypted_payload = encrypted_data[272:]  # AES encrypted data

        print(f"✓ Parsed file structure:")
        print(f"  - Encrypted AES key: {len(encrypted_aes_key)} bytes")
        print(f"  - AES IV: {len(aes_iv)} bytes")
        print(f"  - Encrypted payload: {len(encrypted_payload)} bytes")

        # Step 1: Decrypt AES key using RSA private key
        aes_key = private_key.decrypt(
            encrypted_aes_key,
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None
            )
        )
        print(f"✓ Decrypted AES key: {len(aes_key)} bytes")

        # Step 2: Decrypt payload using AES
        cipher = Cipher(algorithms.AES(aes_key), modes.CBC(aes_iv), backend=default_backend())
        decryptor = cipher.decryptor()
        decrypted_padded = decryptor.update(encrypted_payload) + decryptor.finalize()

        # Step 3: Remove PKCS7 padding
        unpadder = sym_padding.PKCS7(128).unpadder()
        decrypted_payload = unpadder.update(decrypted_padded) + unpadder.finalize()

        print(f"✓ Decrypted and unpadded payload: {len(decrypted_payload)} bytes")

        return decrypted_payload

    except Exception as e:
        print(f"✗ Decryption failed: {e}")
        return None

def parse_capture_payload(decrypted_payload):
    """Parse the decrypted JSON payload containing metadata and image"""
    try:
        # Parse JSON payload
        payload_data = json.loads(decrypted_payload.decode('utf-8'))

        print("\n" + "=" * 60)
        print("DECRYPTED CAPTURE DATA:")
        print("=" * 60)

        # Extract and display metadata
        if 'metadata' in payload_data:
            metadata = payload_data['metadata']
            print("\n📋 FORENSIC METADATA:")
            print("-" * 30)

            # Timestamp info
            if 'timestamp' in metadata:
                ts = metadata['timestamp']
                dt = datetime.fromtimestamp(ts)
                print(f"Capture Time: {dt.strftime('%Y-%m-%d %H:%M:%S')} ({ts})")

            if 'timestamp_iso' in metadata:
                print(f"ISO Timestamp: {metadata['timestamp_iso']}")

            # Device info
            if 'device_id' in metadata:
                print(f"Device ID: {metadata['device_id']}")

            # System info
            if 'system_info' in metadata:
                sys_info = metadata['system_info']
                print(f"System: {sys_info.get('platform', 'Unknown')}")
                print(f"Node: {sys_info.get('node', 'Unknown')}")
                print(f"Python: {sys_info.get('python_version', 'Unknown')}")

            # Image info
            if 'image_info' in metadata:
                img_info = metadata['image_info']
                print(f"Original Size: {img_info.get('original_size', 'Unknown')} bytes")
                print(f"Format: {img_info.get('format', 'Unknown')}")
                print(f"Method: {img_info.get('capture_method', 'Unknown')}")

            # Encryption info
            if 'encryption_info' in metadata:
                enc_info = metadata['encryption_info']
                print(f"Encryption: {enc_info.get('method', 'Unknown')}")
                print(f"RSA Key Size: {enc_info.get('rsa_key_size', 'Unknown')} bits")
                print(f"AES Key Size: {enc_info.get('aes_key_size', 'Unknown')} bits")

        # Extract image data
        if 'image_data' in payload_data:
            image_hex = payload_data['image_data']
            image_bytes = bytes.fromhex(image_hex)

            print(f"\n🖼️  IMAGE DATA:")
            print("-" * 30)
            print(f"Image Size: {len(image_bytes)} bytes")
            print(f"First 20 bytes (hex): {image_bytes[:20].hex()}")

            # Check JPEG magic bytes
            if image_bytes[:2] == b'\xff\xd8':
                print("✓ Valid JPEG file (FFD8 magic bytes)")
            else:
                print("✗ Invalid or corrupted JPEG data")

            return payload_data, image_bytes

        return payload_data, None

    except json.JSONDecodeError as e:
        print(f"✗ Failed to parse JSON payload: {e}")
        return None, None
    except Exception as e:
        print(f"✗ Error parsing payload: {e}")
        return None, None

def save_decrypted_data(payload_data, image_bytes):
    """Save the decrypted data to files"""
    try:
        # Save metadata
        if payload_data and 'metadata' in payload_data:
            with open('decrypted_metadata.json', 'w') as f:
                json.dump(payload_data['metadata'], f, indent=2)
            print("✓ Metadata saved to decrypted_metadata.json")

        # Save image
        if image_bytes:
            with open('decrypted_image.jpg', 'wb') as f:
                f.write(image_bytes)
            print("✓ Image saved to decrypted_image.jpg")

            # Also save raw payload
            with open('decrypted_payload.json', 'w') as f:
                json.dump(payload_data, f, indent=2)
            print("✓ Full payload saved to decrypted_payload.json")

    except Exception as e:
        print(f"✗ Failed to save decrypted data: {e}")

def main():
    """Main decoder function"""
    print("Guard-e-Loo Production Capture Decoder")
    print("Decodes hybrid RSA+AES encrypted captures")
    print("=" * 50)

    # File paths
    encrypted_file = "capture_encrypted.bin"
    private_key_file = "police_private.pem"

    # Check if files exist
    if not os.path.exists(encrypted_file):
        print(f"✗ Encrypted file not found: {encrypted_file}")
        return False

    if not os.path.exists(private_key_file):
        print(f"✗ Private key file not found: {private_key_file}")
        return False

    # Load private key
    private_key = load_private_key(private_key_file)
    if not private_key:
        return False

    # Decrypt the file
    decrypted_payload = decrypt_capture_file(encrypted_file, private_key)
    if decrypted_payload is None:
        return False

    # Parse the payload
    payload_data, image_bytes = parse_capture_payload(decrypted_payload)

    if payload_data is None:
        return False

    # Save decrypted data
    save_decrypted_data(payload_data, image_bytes)

    print("\n" + "=" * 60)
    print("✅ DECRYPTION COMPLETED SUCCESSFULLY!")
    print("✅ Full image + metadata decrypted and saved")
    if image_bytes:
        print("✅ decrypted_image.jpg should be viewable in any image viewer")
    print("=" * 60)

    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)