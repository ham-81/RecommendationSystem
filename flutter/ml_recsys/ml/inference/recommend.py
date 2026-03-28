import torch
import numpy as np
import faiss
import time

from ml.models.dssm_vidrec_model import DSSM_VIDREC

VERIFY_RECOMMENDATIONS = False
TOP_K = 10

print("\n==============================")
print("RECOMMENDATION SYSTEM STARTED")
print("==============================\n")

# LOAD MODEL
model = DSSM_VIDREC()
model.load_state_dict(torch.load("ml/models/dssm_model.pth"))
model.eval()

print("[INFO] Model loaded successfully\n")

# LOAD FAISS INDEX
index = faiss.read_index("ml/inference/reel_index.faiss")
print("[INFO] FAISS index loaded\n")

# EMBEDDING CACHE
video_tensor = None

def load_embeddings():
    global video_tensor

    if video_tensor is not None:
        return video_tensor

    print("[INFO] Loading embeddings into memory...")

    image = np.load("data/embeddings/MicroLens-100k_image_features_CLIPRN50.npy")
    video = np.load("data/embeddings/MicroLens-100k_video_features_VideoMAE.npy")
    text = np.load("data/embeddings/MicroLens-100k_title_en_text_features_BgeM3.npy")

    video_embeddings = np.concatenate([image, video, text], axis=1)

    # Normalize ITEM embeddings
    faiss.normalize_L2(video_embeddings)

    video_tensor = torch.tensor(video_embeddings, dtype=torch.float32)

    print(f"[INFO] Reel embeddings loaded: {video_embeddings.shape}")

    return video_tensor

# EXPLAINABILITY
def explain_recommendation(score, rank):

    reasons = []

    if score > 0.7:
        reasons.append("high similarity to your interests")

    if rank < 5:
        reasons.append("similar to recently watched content")

    if rank > 10:
        reasons.append("added for diversity")

    if not reasons:
        reasons.append("based on your activity")

    return reasons

# SINGLE USER RECOMMENDATION
def recommend(user_sequence, top_k=TOP_K):

    start_time = time.time()

    vt = load_embeddings()

    seq_embed = vt[user_sequence].unsqueeze(0)
    user_vec = model.encode_user(seq_embed)

    # Normalize USER embedding 
    user_vec = torch.nn.functional.normalize(user_vec, dim=1)

    user_vec = user_vec.detach().numpy()

    faiss.normalize_L2(user_vec)

    scores, indices = index.search(user_vec, top_k + len(user_sequence))

    results = []
    seen = set(user_sequence)

    for rank, (idx, score) in enumerate(zip(indices[0], scores[0])):

        if idx in seen:
            continue

        # DIVERSITY BOOST
        if idx in results:
            continue

        score = score - (rank * 0.005)

        reasons = explain_recommendation(score, rank)

        if VERIFY_RECOMMENDATIONS:
            print(f"Reel {idx} (score: {score:.4f})")

        results.append({
            "reel_id": int(idx),
            "score": float(score),
            "reasons": reasons
        })

        if len(results) == top_k:
            break

    end_time = time.time()
    print(f"[PERF] Recommendation time: {end_time - start_time:.4f} sec")

    return results

# MULTI USER RECOMMENDATION
def recommend_multiple(user_sequences, top_k=TOP_K):

    print("==============================")
    print("MULTI-USER RECOMMENDATION")
    print("==============================")

    all_results = {}

    for user_id, seq in user_sequences.items():

        print(f"\n[INFO] User {user_id + 1} → History: {seq}")

        recs = recommend(seq, top_k)

        all_results[user_id] = recs

    return all_results


# DEMO
if __name__ == "__main__":

    import random

    # Generating random user histories
    users = {
        i: random.sample(range(0, len(load_embeddings())), random.randint(5, 10))
        for i in range(10)
    }

    results = recommend_multiple(users)

    print("\n==============================")
    print("FINAL OUTPUT")
    print("==============================")

    for user_id, recs in results.items():
        print(f"\nUser {user_id + 1}:")

        for r in recs:
            print(f"Reel {r['reel_id']} (score: {r['score']:.3f}) → {', '.join(r['reasons'])}")
