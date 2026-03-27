import os

print("\nRunning Full Recommendation Pipeline\n")

os.system("python -m ml.scripts.inspect_dataset")

os.system("python -m ml.preprocessing.build_sequences")

os.system("python -m ml.training.train_dssm")

os.system("python -m ml.inference.build_faiss_index")

os.system("python -m ml.inference.recommend")

print("\nPipeline completed successfully.")