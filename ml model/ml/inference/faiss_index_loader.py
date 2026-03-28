import faiss

index_path = "ml/inference/reel_index.faiss"

loaded_index = faiss.read_index(index_path)

print("FAISS index loaded successfully.")
print(f"Number of vectors in the index: {loaded_index.ntotal}")
