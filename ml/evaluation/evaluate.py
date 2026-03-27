import torch
import numpy as np
import faiss
import pandas as pd

from ml.models.dssm_vidrec_model import DSSM_VIDREC

TOP_K = 10

print("\n==============================")
print("EVALUATION STARTED")
print("==============================\n")

# LOAD MODEL
model = DSSM_VIDREC()
model.load_state_dict(torch.load("ml/models/dssm_model.pth"))
model.eval()

# LOAD FAISS
index = faiss.read_index("ml/inference/reel_index.faiss")

# LOAD TEST DATA
test_inputs = pd.read_pickle("data/processed/test_inputs.pkl")
test_targets = pd.read_pickle("data/processed/test_targets.pkl")

# LOAD EMBEDDINGS
image = np.load("data/embeddings/MicroLens-100k_image_features_CLIPRN50.npy")
video = np.load("data/embeddings/MicroLens-100k_video_features_VideoMAE.npy")
text = np.load("data/embeddings/MicroLens-100k_title_en_text_features_BgeM3.npy")

video_embeddings = np.concatenate([image, video, text], axis=1)
faiss.normalize_L2(video_embeddings)

video_tensor = torch.tensor(video_embeddings, dtype=torch.float32)

# METRICS
def precision_at_k(recommended, target, k):
    return int(target in recommended[:k]) / k

def recall_at_k(recommended, target, k):
    return int(target in recommended[:k])

def ndcg_at_k(recommended, target, k):
    if target in recommended[:k]:
        rank = recommended.index(target) + 1
        return 1 / np.log2(rank + 1)
    return 0

# EVALUATION LOOP
total_precision = 0
total_recall = 0
total_ndcg = 0
num_users = len(test_inputs)

for seq, target in zip(test_inputs, test_targets):

    seq = [i - 1 for i in seq]
    target = target - 1

    seq_embed = video_tensor[seq].unsqueeze(0)

    with torch.no_grad():
        user_vec = model.encode_user(seq_embed)
        user_vec = torch.nn.functional.normalize(user_vec, dim=1)
        user_vec = user_vec.numpy()

    faiss.normalize_L2(user_vec)

    scores, indices = index.search(user_vec, TOP_K)

    recommended = indices[0].tolist()

    p = precision_at_k(recommended, target, TOP_K)
    r = recall_at_k(recommended, target, TOP_K)
    n = ndcg_at_k(recommended, target, TOP_K)

    total_precision += p
    total_recall += r
    total_ndcg += n

# RESULTS
avg_precision = total_precision / num_users
avg_recall = total_recall / num_users
avg_ndcg = total_ndcg / num_users

print(f"Precision@{TOP_K}: {avg_precision:.4f}")
print(f"Recall@{TOP_K}: {avg_recall:.4f}")
print(f"NDCG@{TOP_K}: {avg_ndcg:.4f}")

print("\n==============================")
print("EVALUATION COMPLETED")
print("==============================\n")