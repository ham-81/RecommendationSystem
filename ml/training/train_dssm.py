import torch
from torch.utils.data import DataLoader
from torch.nn.utils.rnn import pad_sequence
from ml.models.dssm_vidrec_model import DSSM_VIDREC
from ml.training.dataset_dssm import DSSMDataset

# Settings
BATCH_SIZE = 64
EPOCHS = 5
MAX_SEQ_LEN = 10

# Collate function to handle the padding of sequences to same length
def collate_fn(batch):
    seqs, pos, neg = zip(*batch)
    trimmed = []
    for s in seqs:
        if len(s) > MAX_SEQ_LEN:
            s = s[-MAX_SEQ_LEN:]
        trimmed.append(s.clone())
    seqs = pad_sequence(trimmed, batch_first=True)
    pos = torch.stack(pos)
    neg = torch.stack(neg)
    return seqs, pos, neg

# Training
def train():

    print("\n==============================")
    print("DSSM TRAINING STARTED")
    print("==============================")

    dataset = DSSMDataset()

    print("\n[INFO] Dataset loaded")
    print(f"[INFO] Total training samples: {len(dataset)}\n")

    loader = DataLoader(
        dataset,
        batch_size = BATCH_SIZE,
        shuffle = True,
        num_workers = 2,
        collate_fn = collate_fn
    )

    print("[INFO] DataLoader initialized")
    print(f"[INFO] Batch size: {BATCH_SIZE}")
    print(f"[INFO] Epochs: {EPOCHS}\n")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    
    print(f"[INFO] Using device: {device}\n")

    model = DSSM_VIDREC().to(device)

    optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

    def bpr_loss(pos, neg):
        return -torch.mean(torch.log(torch.sigmoid(pos - neg) + 1e-8))

    for epoch in range(EPOCHS):

        print("\n----------------------------------")
        print(f"STARTING EPOCH {epoch+1}")
        print("----------------------------------")

        total_loss = 0
        for i, (seq, pos, neg) in enumerate(loader):
            seq = seq.to(device)
            pos = pos.to(device)
            neg = neg.to(device)
            optimizer.zero_grad()
            pos_score, neg_score = model(seq, pos, neg)
            loss = bpr_loss(pos_score, neg_score)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()

            if i % 100 == 0:
                print(f"[Batch {i}] Loss: {loss.item():.4f}")

        print(f"\n[Epoch {epoch+1} Completed]")
        print(f"Total Epoch Loss: {total_loss:.4f}\n")

    torch.save(model.state_dict(), "ml/models/dssm_model.pth")

    print("\n==============================")
    print("TRAINING COMPLETED")
    print("==============================")

    print("\nModel saved at:")
    print("ml/models/dssm_model.pth\n")

if __name__ == "__main__":
    train()