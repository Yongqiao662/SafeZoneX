# SafeZoneX AI-Powered Backend Server

## Overview
This backend powers the SafeZoneX campus safety application, providing AI-driven safety report processing, real-time alerting, and feedback integration. It is built with Node.js, Express, and MongoDB, and supports machine learning model retraining based on user feedback.

---

## Features
- **AI Feedback Loop:** Safety reports are processed by an AI model. If the model's confidence is low, user feedback is requested to improve accuracy.
- **Real-Time Alerts:** Emergency alerts are broadcast instantly to connected clients via WebSocket.
- **MongoDB Integration:** All data is stored in a scalable document database.
- **Machine Learning Retraining:** Retained scripts and metadata allow further model training using new feedback data.
- **Modular Models:** Includes models for users, alerts, feedback, and walk sessions.

---

## Folder Structure
```
backend/
├── .env
├── feedbackApi.js
├── logs/
│   └── [server logs]
├── models/
│   ├── Alert.js
│   ├── Feedback.js
│   ├── TrainingDataModels.js
│   ├── User.js
│   └── WalkSession.js
├── model_metadata_enhanced.json
├── model_metadata_high_accuracy.json
├── node_modules/
├── package-lock.json
├── package.json
├── README.md
├── safety_report_classifier_enhanced.pkl
├── safety_report_classifier_high_accuracy.pkl
├── server.js
├── tfidf_vectorizer_enhanced.pkl
├── tfidf_vectorizer_high_accuracy.pkl
├── train_high_accuracy.py
├── train_ml_enhanced.py
```

---

## Setup Instructions

### 1. Clone the Repository
```sh
git clone <repository-url>
```

### 2. Install Dependencies
```sh
cd backend
npm install
```

### 3. Configure Environment Variables
Create a `.env` file in the `backend` directory with the following content:
```ini
# MongoDB Configuration
MONGODB_URI=mongodb+srv://<username>:<password>@<cluster-url>/<database>?retryWrites=true&w=majority&appName=SafeZoneX

# Server Configuration
NODE_ENV=development
PORT=8080
HOST=localhost

# API Configuration
API_VERSION=v1
API_BASE_URL=http://localhost:8080/api

# Security Configuration
JWT_SECRET=your_jwt_secret
SESSION_SECRET=your_session_secret
ENCRYPTION_KEY=your_encryption_key
```
Replace `<username>`, `<password>`, `<cluster-url>`, and `<database>` with your actual MongoDB Atlas credentials.

### 4. Start MongoDB
Ensure MongoDB is running locally or accessible via the connection string in `.env`.

### 5. Run the Backend
```sh
node server.js
```
The server will run at `http://localhost:8080`.

---

## Usage & API
- **Safety Report Submission:** Send POST requests to `/api/reports` to submit safety reports.
- **Feedback Loop:** If the AI model's confidence is low, the backend will request user feedback via the frontend widget.
- **WebSocket Alerts:** Clients can connect to the WebSocket endpoint for real-time emergency alerts.

---

## Machine Learning & Retraining
- **Model Files:** `.pkl` files are used for AI predictions.
- **Training Scripts:** Use `train_high_accuracy.py` and `train_ml_enhanced.py` to retrain models with new feedback data.
- **Metadata:** JSON files store model metadata for reproducibility and versioning.

---

## Code Review Checklist
- `server.js`: Main backend logic, Express setup, MongoDB connection, AI feedback loop.
- `models/`: Mongoose schemas for core entities.
- `feedbackApi.js`: Handles feedback-related API endpoints.
- ML scripts and metadata: For retraining and improving model accuracy.

---

## Logs
- Server logs are stored in the `logs/` directory for debugging and monitoring.

---

## Frontend Integration
- The backend exposes endpoints for the frontend feedback widget.
- Feedback from users is used to improve AI model accuracy over time.

---

## Contact & Support
For questions or support, contact the SafeZoneX backend team.
