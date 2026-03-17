import torch

def cosine_similarity(user_vec, item_vecs):

    user_vec = user_vec / user_vec.norm(dim=1, keepdim=True)

    item_vecs = item_vecs / item_vecs.norm(dim=1, keepdim=True)

    scores = torch.matmul(user_vec, item_vecs.T)

    return scores