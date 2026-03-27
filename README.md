# 🎥 Reel Recommendation System

A full-stack machine learning project that replicates modern short-video recommendation systems (like Instagram Reels / YouTube Shorts) using a **DSSM-based deep learning model + FAISS retrieval**, integrated with a **Flutter frontend and FastAPI backend**.

---

## 📌 Overview

Modern recommendation systems are often:
- ❌ Opaque  
- ❌ Hard to customize  
- ❌ Struggle with new users (cold start)  
- ❌ Become repetitive over time  

This project solves that by building a **transparent, modular, and efficient recommendation system** that adapts dynamically to user behavior.

---

## 🎯 Problem Statement

> Existing social media platforms provide limited control and transparency over recommendations.  
> New users receive irrelevant content, while existing users often face repetitive suggestions.

---

## 💡 Proposed Solution

We developed a **Reel Recommendation System** that:

- Learns from **user interaction sequences**
- Uses **deep neural networks (DSSM)** for personalization
- Retrieves recommendations efficiently using **FAISS**
- Supports both:
  - 🆕 New users (cold start)
  - 🔁 Returning users (behavior-based recommendations)

---

## 🏗️ System Architecture

Frontend (Flutter)
↓
FastAPI Backend
↓
DSSM Model (User + Item Embeddings)
↓
FAISS Index (Fast Retrieval)
↓
Top-K Recommendations

---

## ⚙️ Tech Stack

### 🔹 Frontend
- Flutter (Reel-style UI)

### 🔹 Backend
- FastAPI

### 🔹 Database
- MongoDB (planned / optional)

### 🔹 Machine Learning
- PyTorch (DSSM model)
- FAISS (similarity search)

### 🔹 Data
- MicroLens-100k dataset

---

## 📁 Project Structure


## 📅 Project Timeline (Summary)
- Week 1–2: Research + Dataset
- Week 3: ML model
- Week 4: Backend
- Week 5: Frontend
- Week 6: Integration
- Week 7: Optimization
- Week 8: Testing
- Week 9: Final delivery

## 👨‍💻 Team

Mentees: 
- Adhithya S R
- Ashutosh Gupta
- Darshan Sai Naath
- Shashank Gupta

Mentors:

- Aryan
- Dhruva Vinod
- Hanna Abdul Majeed
- Shreyan

## 💬 Final Note

This project demonstrates a complete end-to-end recommendation system, combining:

- Deep learning
- Efficient retrieval
- Real-time serving
- Full-stack integration

---

⭐ Feel free to explore and build on top of it!!!
