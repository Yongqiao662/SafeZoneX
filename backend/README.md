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

Your `.env` file should look like this:
```ini
# MongoDB Configuration
MONGODB_URI=mongodb+srv://YongQiao:<db_password>@safezonex.s70xg0u.mongodb.net/?retryWrites=true&w=majority&appName=SafeZoneX

# Server Configuration
NODE_ENV=development
PORT=8080
HOST=localhost

# API Configuration
API_VERSION=v1
API_BASE_URL=http://localhost:8080/api

# Security Configuration
JWT_SECRET=safezonex_super_secret_key_2025_ml_training_system
SESSION_SECRET=safezonex_session_secret_ml_ai_powered_security
ENCRYPTION_KEY=safezonex_encryption_key_for_sensitive_data_2025
```
Replace `<db_password>` with your actual database password.

### 4. Start MongoDB
Ensure MongoDB is running locally or accessible via the connection string in `.env`.

### 5. Run the Backend
```sh
node server.js
```
The server will run at `http://localhost:8080`.

---

## Usage & API
- **Safety Report Submission:** Send POST requests to `/api/report` to submit safety reports from the mobile app or other clients.
- **AI Analysis Flow:**
	- Reports are analyzed by the AI model.
	- If confidence > 70%, the report is sent to the dashboard as real.
	- If confidence is 50-70%, the report is sent as likely real with confidence level.
	- If confidence < 50%, the report is filtered and not sent to the dashboard.
- **Feedback Loop:** If the AI model's confidence is in the 50-70% range, the backend will request user feedback via the frontend widget.
- **WebSocket Alerts:** Clients can connect to the WebSocket endpoint for real-time emergency alerts and report updates.

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
- The backend exposes endpoints for the mobile app and web dashboard.
- Mobile app submits reports via `/api/report`.
- Web dashboard receives real-time updates via Socket.IO.
- Feedback from users is used to improve AI model accuracy over time.

---

## Contact & Support
For questions or support, contact the SafeZoneX backend team.
