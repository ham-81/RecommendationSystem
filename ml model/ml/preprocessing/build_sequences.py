import pandas as pd
import os

# Loading dataset
pairs = pd.read_csv("data/raw/MicroLens-100k_pairs.csv")

print("\n==============================")
print("SEQUENCE GENERATION SUMMARY")
print("==============================")

print("\nOriginal dataset shape:", pairs.shape)

# Sort interactions by time
pairs = pairs.sort_values(by=["user", "timestamp"])

# Group videos watched by each user
user_sequences = pairs.groupby("user")["item"].apply(list)

print(f"Total users processed: {len(user_sequences)}")

# Convert sequences into training samples
inputs = []
targets = []

for seq in user_sequences:
    
    if len(seq) < 2:
        continue
        
    for i in range(1, len(seq)):
        
        input_seq = seq[:i]
        target = seq[i]
        
        inputs.append(input_seq)
        targets.append(target)

print(f"Total training samples created: {len(inputs)}")

# Saving processed data
os.makedirs("data/processed", exist_ok=True)

pd.to_pickle(inputs, "data/processed/train_inputs.pkl")
pd.to_pickle(targets, "data/processed/train_targets.pkl")

print("\nExample training sample:")
print("Input sequence:", inputs[0])
print("Target reel:", targets[0])

print("\nSequences saved to data/processed/\n")