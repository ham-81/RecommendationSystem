import numpy as np
import torch
import faiss
from ml.models.dssm_vidrec_model import DSSM_VIDREC

print("\n==============================")
print("FAISS INDEX BUILD STARTED")
print("==============================\n")

# Load trained model
print("[STEP] Loading trained DSSM model...")
model = DSSM_VIDREC()
model.load_state_dict(torch.load("ml/models/dssm_model.pth"))
model.eval()

print("[INFO] Model loaded successfully\n")

# Load raw embeddings
print("[STEP] Loading multimodal reel embeddings...")
image = np.load("data/embeddings/MicroLens-100k_image_features_CLIPRN50.npy")
video = np.load("data/embeddings/MicroLens-100k_video_features_VideoMAE.npy")
text = np.load("data/embeddings/MicroLens-100k_title_en_text_features_BgeM3.npy")

print("[INFO] Image embeddings shape:", image.shape)
print("[INFO] Video embeddings shape:", video.shape)
print("[INFO] Text embeddings shape:", text.shape)

#Combine Embeddings
video_embeddings = np.concatenate([image, video, text], axis=1)
print("\n[INFO] Combined embedding shape:", video_embeddings.shape)

# Encode reels using item tower
print("\n[STEP] Encoding reels using DSSM item tower...")
video_tensor = torch.tensor(video_embeddings, dtype=torch.float32)

with torch.no_grad():
    reel_vectors = model.encode_item(video_tensor).numpy()

print("[INFO] Encoded reel vector shape:", reel_vectors.shape)

#Build Faiss Index
print("[INFO] Encoded reel vector shape:", reel_vectors.shape)
dimension = reel_vectors.shape[1]

index = faiss.IndexFlatIP(dimension)

faiss.normalize_L2(reel_vectors)

index.add(reel_vectors)

print("[INFO] Total reels indexed:", reel_vectors.shape[0])
print("[INFO] Vector dimension:", dimension)

#Save Index
faiss.write_index(index, "ml/inference/reel_index.faiss")

print("\n==============================")
print("FAISS INDEX BUILD COMPLETE")
print("==============================")

print("\nIndex saved at:")
print("ml/inference/reel_index.faiss\n")