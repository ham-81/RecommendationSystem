import torch
import torch.nn as nn
import torch.nn.functional as F

class DSSM_VIDREC(nn.Module):

    def __init__(self, video_embedding_dim=2816, hidden_dim=512, output_dim=128):

        super().__init__()

        # Item Tower (Video Encoder)
        self.item_tower = nn.Sequential(
            nn.Linear(video_embedding_dim, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(hidden_dim, output_dim)
        )

        # User Tower (Sequence Encoder)
        self.user_gru = nn.GRU(
            input_size = video_embedding_dim,
            hidden_size = hidden_dim,
            batch_first = True
        )

        # Attention layer
        self.attention = nn.Linear(hidden_dim, 1)

        self.user_projection = nn.Linear(hidden_dim, output_dim)


    # User Encoder
    def encode_user(self, sequence_embeddings):

        outputs, _ = self.user_gru(sequence_embeddings)

        # Attention weights
        attn_weights = torch.softmax(self.attention(outputs), dim=1)

        # Weighted sum
        context = torch.sum(attn_weights * outputs, dim=1)

        user_vec = self.user_projection(context)

        user_vec = F.normalize(user_vec, dim=1)

        return user_vec


    # Item Encoder
    def encode_item(self, item_embedding):

        item_vec = self.item_tower(item_embedding)

        item_vec = F.normalize(item_vec, dim=1)

        return item_vec


    # Pushing forward
    def forward(self, seq_embeddings, pos_item, neg_item):

        user_vec = self.encode_user(seq_embeddings)

        pos_vec = self.encode_item(pos_item)

        neg_vec = self.encode_item(neg_item)

        pos_score = torch.sum(user_vec * pos_vec, dim=1)

        neg_score = torch.sum(user_vec * neg_vec, dim=1)

        return pos_score, neg_score