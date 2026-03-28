import pandas as pd
import os

print("\n==============================")
print("SEQUENCE GENERATION STARTED")
print("==============================")

# Load dataset
pairs = pd.read_csv("data/raw/MicroLens-100k_pairs.csv")

print("\nOriginal dataset shape:", pairs.shape)

# Sort interactions by time
pairs = pairs.sort_values(by=["user", "timestamp"])

# Group videos per user
user_sequences = pairs.groupby("user")["item"].apply(list)

print(f"Total users processed: {len(user_sequences)}")

train_inputs, train_targets = [], []
val_inputs, val_targets = [], []
test_inputs, test_targets = [], []

# PER USER TEMPORAL SPLIT (TRAIN / VAL / TEST)
for seq in user_sequences:

    # Need at least 4 items to create all splits
    if len(seq) < 4:
        continue

    # TRAIN DATA (all except last 2)
    for i in range(1, len(seq) - 2):
        train_inputs.append(seq[:i])
        train_targets.append(seq[i])

    # VALIDATION DATA (second last)
    val_inputs.append(seq[:-2])
    val_targets.append(seq[-2])

    # TEST DATA (last interaction)
    test_inputs.append(seq[:-1])
    test_targets.append(seq[-1])

print(f"\nTrain samples: {len(train_inputs)}")
print(f"Validation samples: {len(val_inputs)}")
print(f"Test samples: {len(test_inputs)}")

# SAVE FILES
os.makedirs("data/processed", exist_ok=True)

pd.to_pickle(train_inputs, "data/processed/train_inputs.pkl")
pd.to_pickle(train_targets, "data/processed/train_targets.pkl")

pd.to_pickle(val_inputs, "data/processed/val_inputs.pkl")
pd.to_pickle(val_targets, "data/processed/val_targets.pkl")

pd.to_pickle(test_inputs, "data/processed/test_inputs.pkl")
pd.to_pickle(test_targets, "data/processed/test_targets.pkl")

print("\nFiles saved to data/processed/")