import numpy as np
import torch
import faiss
from ml.models.dssm_vidrec_model import DSSM_VIDREC

print("\n==============================")
print("FAISS INDEX BUILDING STARTED")
print("==============================\n")

# LOAD MODEL
print("[STEP] Loading trained DSSM model...")

model = DSSM_VIDREC()
model.load_state_dict(torch.load("ml/models/dssm_model.pth"))
model.eval()

print("[INFO] Model loaded\n")

# LOAD RAW EMBEDDINGS
print("[STEP] Loading raw embeddings...")

image = np.load("data/embeddings/MicroLens-100k_image_features_CLIPRN50.npy")
video = np.load("data/embeddings/MicroLens-100k_video_features_VideoMAE.npy")
text = np.load("data/embeddings/MicroLens-100k_title_en_text_features_BgeM3.npy")

video_embeddings = np.concatenate([image, video, text], axis=1)

video_tensor = torch.tensor(video_embeddings, dtype=torch.float32)

print(f"[INFO] Raw embedding shape: {video_embeddings.shape}\n")

# ENCODE INTO LATENT SPACE (128)
print("[STEP] Encoding embeddings using model...")

with torch.no_grad():
    item_embeddings = model.encode_item(video_tensor).numpy()

print(f"[INFO] Encoded embedding shape: {item_embeddings.shape}\n")

# NORMALIZE
print("[STEP] Normalizing embeddings...")

faiss.normalize_L2(item_embeddings)

print("[INFO] Normalization done\n")

# BUILD INDEX
dim = item_embeddings.shape[1]

print("[STEP] Building FAISS index...")

index = faiss.IndexFlatIP(dim)
index.add(item_embeddings)

print(f"[INFO] Indexed {index.ntotal} items\n")

# SAVE
faiss.write_index(index, "ml/inference/reel_index.faiss")

print("[INFO] Index saved\n")

print("==============================")
print("FAISS BUILD COMPLETED")
print("==============================\n")