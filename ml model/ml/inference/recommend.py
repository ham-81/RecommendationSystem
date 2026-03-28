import torch
import numpy as np
import faiss
import json
import os
from urllib import request, error
from ml.models.dssm_vidrec_model import DSSM_VIDREC

print("\n==============================")
print("RECOMMENDATION SYSTEM STARTED")
print("==============================\n")

# Load trained model
print("[STEP] Loading trained DSSM model...")

model = DSSM_VIDREC()
model.load_state_dict(torch.load("ml/models/dssm_model.pth"))
model.eval()

print("[INFO] Model loaded successfully\n")

# Load FAISS index
print("[STEP] Loading FAISS retrieval index...")

index = faiss.read_index("ml/inference/reel_index.faiss")

print("[STEP] Loading FAISS retrieval index...")

#Load Embeddings
print("[STEP] Loading reel embeddings...")

image = np.load("data/embeddings/MicroLens-100k_image_features_CLIPRN50.npy")
video = np.load("data/embeddings/MicroLens-100k_video_features_VideoMAE.npy")
text = np.load("data/embeddings/MicroLens-100k_title_en_text_features_BgeM3.npy")

video_embeddings = np.concatenate([image, video, text], axis=1)

video_tensor = torch.tensor(video_embeddings, dtype=torch.float32)

print("[INFO] Reel embeddings loaded\n")

#Recommend Function
def recommend(user_sequence, top_k = 10):

    print("[STEP] Generating user embedding...")

    seq_embed = video_tensor[user_sequence].unsqueeze(0)

    user_vec = model.encode_user(seq_embed).detach().numpy()

    print("[INFO] User embedding generated")

    print("\n[STEP] Searching FAISS index...")

    faiss.normalize_L2(user_vec)

    scores, indices = index.search(user_vec, top_k)

    print("[INFO] Retrieval complete\n")

    return indices[0]


def publish_recommendations(user_id, reel_ids):
    api_url = os.getenv("RECO_API_URL", "http://127.0.0.1:8000/recommendations")
    payload = {
        "user_id": int(user_id),
        "reel_ids": [int(r) for r in reel_ids],
        "model_version": os.getenv("MODEL_VERSION", "dssm-faiss-v1"),
    }

    req = request.Request(
        api_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with request.urlopen(req, timeout=10) as response:
            if response.status in (200, 201):
                print(f"[INFO] Recommendations published for user {user_id}")
                return
            print(f"[WARN] Publish failed with status: {response.status}")
    except error.URLError as exc:
        print(f"[WARN] Could not publish recommendations to API: {exc}")

#Test Recommendation (Comment down the whole thing below once tested)
example_user = [10, 25, 90]
example_user_id = int(os.getenv("USER_ID", "1"))

print("User watch history:", example_user)

recs = recommend(example_user)
publish_recommendations(example_user_id, recs)

print("==============================")
print("TOP RECOMMENDED REELS")
print("==============================\n")

for rank, reel in enumerate(recs, start=1):
    print(f"{rank}. Reel ID → {reel}")

print("\nRecommendation pipeline completed.\n")