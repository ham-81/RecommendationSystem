# Reel Recommendation System (DSSM + FAISS)

This project implements a video recommendation system using the MicroLens-100k dataset.

## Features

- Multimodal embeddings (image, video, text)
- DSSM dual-tower architecture
- Sequential user modeling (GRU + Attention)
- FAISS-based fast retrieval
- Top-K reel recommendation

## Pipeline

User interactions → Sequence generation → DSSM training → FAISS indexing → Recommendations

## Run

```bash
python -m ml.scripts.inspect_dataset
python -m ml.preprocessing.build_sequences
python -m ml.training.train_dssm
python -m ml.inference.build_faiss_index
python -m ml.inference.recommend


## 🔥 Key Features

- 🎯 Multimodal embeddings (image + video + text)
- 🧠 DSSM dual-tower architecture
- 🔁 Sequential modeling (GRU + Attention)
- ⚡ FAISS-based fast retrieval
- 📊 Evaluation with Precision@K, Recall@K, NDCG@K
- 👥 Supports new & returning users
- 📱 API-based real-time recommendations

---

## 📊 Model Details

### DSSM Architecture
- User Tower → GRU + Attention
- Item Tower → Feedforward network

### Training Improvements
- Hard negative sampling  
- Margin-based ranking loss  
- Temporal data split (no leakage)  

## 📈 Evaluation Metrics

- **Precision@K** → recommendation accuracy  
- **Recall@K** → coverage of relevant items  
- **NDCG@K** → ranking quality  

---
