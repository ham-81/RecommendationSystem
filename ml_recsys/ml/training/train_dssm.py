import torch
from torch.utils.data import DataLoader, random_split
from torch.nn.utils.rnn import pad_sequence
import matplotlib.pyplot as plt

from ml.models.dssm_vidrec_model import DSSM_VIDREC
from ml.training.dataset_dssm import DSSMDataset

# SETTINGS
BATCH_SIZE = 64
EPOCHS = 30
MAX_SEQ_LEN = 10

# COLLATE FUNCTION
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

# TRAIN FUNCTION
def train():

    print("\n==============================")
    print("DSSM TRAINING STARTED")
    print("==============================")

    dataset = DSSMDataset()

    print("\n[INFO] Dataset loaded")
    print(f"[INFO] Total samples: {len(dataset)}\n")

    # SPLIT DATA
    train_size = int(0.8 * len(dataset))
    val_size = int(0.1 * len(dataset))
    test_size = len(dataset) - train_size - val_size

    train_data, val_data, test_data = random_split(
        dataset, [train_size, val_size, test_size]
    )

    print("[INFO] Data Split:")
    print(f"Train: {len(train_data)}")
    print(f"Validation: {len(val_data)}")
    print(f"Test: {len(test_data)}\n")

    # DATALOADERS
    train_loader = DataLoader(
        train_data,
        batch_size = BATCH_SIZE,
        shuffle = True,
        num_workers = 0,
        collate_fn = collate_fn
    )

    val_loader = DataLoader(
        val_data,
        batch_size = BATCH_SIZE,
        shuffle = False,
        num_workers = 0,
        collate_fn = collate_fn
    )

    print("[INFO] DataLoaders initialized\n")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"[INFO] Using device: {device}\n")

    model = DSSM_VIDREC().to(device)

    optimizer = torch.optim.Adam(model.parameters(), lr=0.003)

    def bpr_loss(pos, neg):
        margin = 0.5
        return -torch.mean(torch.log(torch.sigmoid(pos - neg - margin) + 1e-8))

    train_losses = []
    val_losses = []

    best_val_loss = float('inf')

    # TRAIN LOOP
    for epoch in range(EPOCHS):

        print("\n----------------------------------")
        print(f"STARTING EPOCH {epoch+1}")
        print("----------------------------------")

        model.train()
        total_train_loss = 0

        for i, (seq, pos, neg) in enumerate(train_loader):
            seq = seq.to(device)
            pos = pos.to(device)
            neg = neg.to(device)

            optimizer.zero_grad()
            pos_score, neg_score = model(seq, pos, neg)

            loss = bpr_loss(pos_score, neg_score)
            loss.backward()
            optimizer.step()

            total_train_loss += loss.item()

            if i % 100 == 0:
                print(f"[Train Batch {i}] Loss: {loss.item():.4f}")

        # VALIDATION
        model.eval()
        total_val_loss = 0

        with torch.no_grad():
            for seq, pos, neg in val_loader:
                seq = seq.to(device)
                pos = pos.to(device)
                neg = neg.to(device)

                pos_score, neg_score = model(seq, pos, neg)
                loss = bpr_loss(pos_score, neg_score)

                total_val_loss += loss.item()

        avg_train_loss = total_train_loss / len(train_loader)
        avg_val_loss = total_val_loss / len(val_loader)

        train_losses.append(avg_train_loss)
        val_losses.append(avg_val_loss)

        print(f"\n[Epoch {epoch+1}]")
        print(f"Train Loss: {avg_train_loss:.4f}")
        print(f"Val Loss:   {avg_val_loss:.4f}")

        gap = abs(avg_train_loss - avg_val_loss)
        print(f"Gap: {gap:.4f}")

        if avg_val_loss > avg_train_loss:
            print("[INFO] Possible overfitting")
        else:
            print("[INFO] Good generalization")

        if avg_val_loss < best_val_loss:
            best_val_loss = avg_val_loss
            torch.save(model.state_dict(), "ml/models/dssm_best_model.pth")
            print("[INFO] Best model saved")

    # TEST EVALUATION
    print("\n==============================")
    print("TEST SET EVALUATION")
    print("==============================")

    test_loader = DataLoader(
        test_data,
        batch_size = BATCH_SIZE,
        shuffle = False,
        collate_fn = collate_fn
    )

    model.eval()
    hits = 0
    total = 0

    with torch.no_grad():
        for seq, pos, neg in test_loader:
            seq = seq.to(device)
            pos = pos.to(device)

            user_emb = model.encode_user(seq)
            pos_emb = model.encode_item(pos)

            score = torch.sum(user_emb * pos_emb, dim=1)

            hits += (score > 0).sum().item()
            total += len(score)

    accuracy = hits / total
    print(f"\nTest Accuracy (approx): {accuracy:.4f}\n")

    # SAVE FINAL MODEL
    torch.save(model.state_dict(), "ml/models/dssm_model.pth")

    print("Final model saved at:")
    print("ml/models/dssm_model.pth\n")

    # PLOT LOSS
    plt.plot(train_losses, label="Train Loss")
    plt.plot(val_losses, label="Validation Loss")
    plt.legend()
    plt.title("Training vs Validation Loss")
    plt.xlabel("Epoch")
    plt.ylabel("Loss")
    plt.grid()
    plt.show()

    print("\n==============================")
    print("TRAINING COMPLETED")
    print("==============================")


# MAIN
if __name__ == "__main__":
    train()
