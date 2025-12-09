#  Reel Recommendation System

*A Hybrid ML-Based Personalized Reels Recommendation System (Feed Engine)*

---

##  Overview

The Reel Recommendation System is a full-stack machine learning project that delivers a personalized short-video feed, similar to Instagram Reels, TikTok, or YouTube Shorts.
This system focuses on:

*  High-speed recommendations (≤300ms warm latency)
*  Personalization using hybrid ML models
*  Secure, modular backend using FastAPI
*  A clean, scrolling feed UI built in Flutter
*  A transparent, tunable recommendation logic

This README documents the **system architecture**, **workflow**, **datasets**, **research background**, and **project structure**.

---

##  Table of Contents

1. [Project Motivation](#project-motivation)
2. [Key Features](#key-features)
3. [System Architecture](#system-architecture)
4. [Sequence Diagram](#sequence-diagram)
5. [ML Recommendation Pipeline](#ml-recommendation-pipeline)
6. [Dataset & Preprocessing](#dataset--preprocessing)
7. [Tech Stack](#tech-stack)
8. [Project Timeline](#project-timeline)
9. [Repository Structure](#repository-structure)
10. [Team](#team)

---

## Project Motivation

Existing platforms often provide:

* ❌ Repetitive content
* ❌ Poor cold-start recommendations
* ❌ Opaque algorithms

Our solution aims to build a **transparent and efficient** ML-based reel recommendation engine that adapts dynamically to:

* User activity (likes, watch time, skips)
* Similar user behavior
* Reel metadata & embeddings
* Location and popularity trends

This ensures **fairness**, **freshness**, **accuracy**, and **low latency**—making the platform usable for both **new** and **active** users.

---

## Key Features

### Hybrid ML Scoring Model

```
Final Score = 0.5 * Scontent 
            + 0.3 * SCF 
            + 0.1 * Spopularity 
            + 0.1 * Sexploration
```

### High-Performance Backend

* FastAPI for low-latency inference
* Redis caching for warm responses
* MongoDB for user/reel dataset

### Exploration Strategy

* ε-greedy sampling (10–20% exploration)
* Trending content boost
* New‐creator exposure

### Flutter Frontend

* Smooth vertical reel feed
* Like, save, scroll, watch-time events

### Security & Privacy

* JWT authentication
* HTTPS/TLS + rate limiting
* Pseudo-anonymous user IDs

---

## System Architecture

```
Flutter App → Reverse Proxy/WAF → FastAPI → Recommender Engine → Redis Cache → MongoDB
```

### **Major Components**

* **Flutter App** → UI + scroll actions + event batching
* **Reverse Proxy** → TLS, CORS, rate limiting
* **FastAPI Backend** → `/feed`, `/events`, `/admin`
* **Recommender Module** → candidate generation + ranking
* **Redis Cache** → candidate sets, trending, rate limits
* **MongoDB** → users, reels, interactions, embeddings
* **Offline Jobs** → embeddings, CF matrix, popularity refresh

---

## Sequence Diagram

A single `/feed` request behaves as follows:

1. App → GET `/feed?user_id=&limit=`
2. Proxy adds `x-request-id`
3. API → Redis: fetch `user:{id}:candidates`
4. **If cache miss:**

   * Recommender → fetch user history & embeddings
   * Generate top 200-300 candidates
   * Redis SET with TTL
5. API → rank(candidates)
6. Return top-K reels with scores + reasons
7. App POSTs `/events` (batched)
8. FastAPI → MongoDB: idempotent upsert

---

## ML Recommendation Pipeline

### **Stage 1 - Candidate Generation (200–300 reels)**

* Content-based similarity
* Item–item collaborative filtering
* Popularity scoring
* Cache results in Redis (TTL ~5 min)

### **Stage 2 - Ranking**

Uses the hybrid score:

| Component        | Meaning                             |
| ---------------- | ----------------------------------- |
| **Scontent**     | Cosine similarity using embeddings  |
| **SCF**          | Item–item similarity from CF matrix |
| **Spopularity**  | Likes, views, recency               |
| **Sexploration** | Diversity injection                 |

### **Exploration**

* ε ≈ 0.1
* Trending boost
* New-reel boost

This avoids echo chambers & repetition.

---

## Dataset & Preprocessing

Our dataset contains:

* `video_id`, `title`, `tags`
* `duration_sec`, `views`, `likes`, `comments`
* `retention_rate`, `first_3_sec_engagement`
* Cleaned tags/title features

Used for:

* Embedding generation
* CF computation
* Popularity scoring
* Training baseline models

---

## Tech Stack

### **Frontend**

* Flutter
* Dart

### **Backend**

* FastAPI
* Python

### **Database**

* MongoDB
* Redis Cache

### **ML**

* Content-based filtering
* CF + Matrix factorization
* Embeddings
* Hybrid ranking

### **Infra**

* Docker Compose
* Reverse Proxy (Nginx/Caddy)

---

## Project Timeline

### Week-by-week (as per plan)

* **Week 1:** Research, architecture finalization
* **Week 2:** Dataset collection & preparation
* **Week 3:** Initial ML model
* **Week 4:** Backend development
* **Week 5:** Flutter UI prototype
* **Week 6:** Frontend–backend integration
* **Week 7:** Model tuning & exploration logic
* **Week 8:** Testing + bug fixes
* **Week 9:** Final presentation & documentation

---

## Repository Structure

```
reel-recommendation-system
│
├── backend/
│   ├── main.py
│   ├── routes/
│   ├── recommender/
│   │   ├── candidate_generator.py
│   │   ├── ranker.py
│   │   ├── embeddings.py
│   ├── schemas/
│   ├── models/
│   └── utils/
│
├── ml/
│   ├── notebooks/
│   ├── preprocessing/
│   ├── cf_matrix/
│   ├── embeddings/
│   └── popularity/
│
├── frontend/
│   └── flutter_app/
│
├── datasets/
│   └── reels_dataset.csv
│
└── README.md
```

---

## Team

### **Mentees**

* Adhithya S R
* Ashutosh Gupta
* Shashank Gupta
* B Darshan Sai Naath

### **Mentors**

* Aryan
* Dhruva Vinod
* Hanna Abdul Majeed
* Shreyan

---
