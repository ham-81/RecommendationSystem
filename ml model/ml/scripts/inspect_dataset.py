import pandas as pd
import numpy as np

# Load interaction dataset
pairs = pd.read_csv("data/raw/MicroLens-100k_pairs.csv")

print("\n==============================")
print("DATASET INSPECTION")
print("==============================")

print("\n[DATA]")
print("First 5 rows:")
print(pairs.head())

print("\n[SHAPE]")
print("Dataset shape:", pairs.shape)

print("\n[STATS]")
print("Unique users:", pairs['user'].nunique())
print("Unique reels:", pairs['item'].nunique())

# Load embeddings
image_features = np.load("data/embeddings/MicroLens-100k_image_features_CLIPRN50.npy")
video_features = np.load("data/embeddings/MicroLens-100k_title_en_text_features_BgeM3.npy")
text_features = np.load("data/embeddings/MicroLens-100k_video_features_VideoMAE.npy")

print("\n[EMBEDDINGS]")

print("Image embeddings:", image_features.shape)
print("Video embeddings:", video_features.shape)
print("Text embeddings:", text_features.shape)

video_embeddings = np.concatenate(
    [image_features, video_features, text_features],
    axis=1
)

print("\nCombined reel embedding dimension:", video_embeddings.shape)
print("\nDataset inspection complete.\n")