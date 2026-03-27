import torch
from torch.utils.data import Dataset
import pandas as pd
import numpy as np
import random

class DSSMDataset(Dataset):

    def __init__(self):
        self.inputs = pd.read_pickle("data/processed/train_inputs.pkl")[:]
        self.targets = pd.read_pickle("data/processed/train_targets.pkl")[:]

        image = np.load("data/embeddings/MicroLens-100k_image_features_CLIPRN50.npy")
        video = np.load("data/embeddings/MicroLens-100k_video_features_VideoMAE.npy")
        text = np.load("data/embeddings/MicroLens-100k_title_en_text_features_BgeM3.npy")

        self.video_embeddings = np.concatenate([image, video, text], axis=1)
        self.num_videos = self.video_embeddings.shape[0]

    def __len__(self):
        return len(self.inputs)

    def __getitem__(self, idx):

        seq = [i - 1 for i in self.inputs[idx]]
        pos = self.targets[idx] - 1

        while True:
            neg = (pos + random.randint(1, 50)) % self.num_videos
            if neg != pos and neg not in seq:
                break

        seq_embed = self.video_embeddings[seq]
        pos_embed = self.video_embeddings[pos]
        neg_embed = self.video_embeddings[neg]

        return (
            torch.tensor(seq_embed, dtype=torch.float32),
            torch.tensor(pos_embed, dtype=torch.float32),
            torch.tensor(neg_embed, dtype=torch.float32)
        )