## 📊 Dataset Information

> [!IMPORTANT]
> **Data Integrity & Truncation Policy:** Due to GitHub's file size limits (25MB per file), high-volume tables have been strategically downsampled. This repository is optimized to showcase **SQL Architecture and Logic**, rather than serving as a full data mirror.

### 📁 Directory: [datasets/samples/](./samples/)
To ensure repository portability and CI/CD compatibility, the following data handling has been applied:

* **Original Datasets:** Core tables such as `players`, `clubs`, `competitions`, `games`, `player_valuations` and `transfers` are included in their **full, original form**.
* **Truncated Datasets:** High-cardinality fact tables (`appearances`, `game_lineups`, `game_events`) have been **truncated to 25MB**.
* **Version Note:** Development is based on the data snapshot from **March 10, 2026**.
* **Usage:** Use these samples for validating DDL structures, indexing strategies, and pipeline syntax. For full analytical results (e.g., career-long goal trends), download the complete source from Kaggle.

### 🔗 Full Dataset Source: [Transfermarkt: Football Data (Kaggle)](https://www.kaggle.com/datasets/davidcariboo/player-scores)
