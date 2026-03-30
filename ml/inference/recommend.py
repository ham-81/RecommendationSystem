import torch
import torch.nn as nn
import faiss
import numpy as np
import os

# ── paths ──────────────────────────────────────────────────────────────────────
BASE_DIR       = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODEL_PATH     = os.path.join(BASE_DIR, "ml", "models", "model", "dssm_model.pth")
FAISS_PATH     = os.path.join(BASE_DIR, "faiss", "reel_index.faiss")
IMAGE_EMB      = os.path.join(BASE_DIR, "embeddings", "MicroLens-100k_image_features_CLIPRN50.npy")
TEXT_EMB       = os.path.join(BASE_DIR, "embeddings", "MicroLens-100k_title_en_text_features_BgeM3.npy")
VIDEO_EMB      = os.path.join(BASE_DIR, "embeddings", "MicroLens-100k_video_features_VideoMAE.npy")

# ── model definition ───────────────────────────────────────────────────────────
class DSSMModel(nn.Module):
    def __init__(self, input_dim=2816, hidden_dim=512, output_dim=128):
        super().__init__()
        self.item_tower = nn.Sequential(
            nn.Linear(input_dim, hidden_dim),  # 0
            nn.LayerNorm(hidden_dim),           # 1
            nn.ReLU(),                          # 2
            nn.Dropout(0.2),                    # 3
            nn.Linear(hidden_dim, output_dim)   # 4
        )
        self.user_gru        = nn.GRU(input_dim, hidden_dim, batch_first=True)
        self.attention       = nn.Linear(hidden_dim, 1)
        self.user_projection = nn.Linear(hidden_dim, output_dim)

    def forward(self, x):
        return self.item_tower(x)

# ── load everything once at startup ───────────────────────────────────────────
print("Loading embeddings (this may take a moment)...")
image_emb = np.load(IMAGE_EMB).astype("float32")   # shape: (N, dim1)
text_emb  = np.load(TEXT_EMB).astype("float32")    # shape: (N, dim2)
video_emb = np.load(VIDEO_EMB).astype("float32")   # shape: (N, dim3)

# concatenate all 3 modalities → (N, 2816)
all_embeddings = np.concatenate([image_emb, text_emb, video_emb], axis=1)
NUM_REELS = all_embeddings.shape[0]
print(f"  ✓ {NUM_REELS} reels, embedding dim = {all_embeddings.shape[1]}")

print("Loading DSSM model...")
model = DSSMModel(input_dim=all_embeddings.shape[1])
model.load_state_dict(torch.load(MODEL_PATH, map_location="cpu"))
model.eval()
print("  ✓ model ready")

print("Loading FAISS index...")
faiss_index = faiss.read_index(FAISS_PATH)
print(f"  ✓ FAISS ready ({faiss_index.ntotal} vectors)")

# ── main function called by app.py ────────────────────────────────────────────
def recommend(user_sequence: list, top_k: int = 10) -> list:
    """
    user_sequence : list of reel indices (0-based) the user already watched
    returns       : list of recommended reel indices
    """
    if not user_sequence:
        # cold start — return first top_k reels
        return list(range(top_k))

    # 1. fetch embeddings for watched reels (skip out-of-range ids)
    valid = [i for i in user_sequence if 0 <= i < NUM_REELS]
    if not valid:
        return list(range(top_k))

    # 2. mean-pool → single aggregate embedding
    seq_embs = all_embeddings[valid]                                    # (n, 2816)
    mean_emb = torch.tensor(seq_embs).float().mean(dim=0, keepdim=True) # (1, 2816)

    # 3. encode through DSSM → 128-dim user vector
    with torch.no_grad():
        user_vec = model(mean_emb).numpy().astype("float32")            # (1, 128)

    # 4. FAISS nearest-neighbour search
    faiss.normalize_L2(user_vec)
    _, indices = faiss_index.search(user_vec, top_k + len(user_sequence))

    # 5. remove already-watched
    seen = set(user_sequence)
    return [int(i) for i in indices[0] if int(i) not in seen][:top_k]
