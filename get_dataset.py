import os
import fiftyone as fo
import fiftyone.zoo as foz

# Make sure output dirs exist
os.makedirs("data/vandalism", exist_ok=True)
os.makedirs("data/benign", exist_ok=True)

# Download graffiti (as vandalism examples)
graffiti_ds = foz.load_zoo_dataset(
    "open-images-v7",
    split="train",
    label_types=["detections"],
    classes=["Graffiti"],
    max_samples=200,
    dataset_dir="data/vandalism",
)

# Download handbags (as benign examples)
handbag_ds = foz.load_zoo_dataset(
    "open-images-v7",
    split="train",
    label_types=["detections"],
    classes=["Handbag"],
    max_samples=200,
    dataset_dir="data/benign",
)

print("Datasets downloaded to ./data/")
