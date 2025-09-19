import sys
import json
import joblib

# Load model & vectorizer
model_path, vectorizer_path = sys.argv[1], sys.argv[2]
model = joblib.load(model_path)
vectorizer = joblib.load(vectorizer_path)

# Read input JSON
raw_input = sys.stdin.read()
data = json.loads(raw_input)
description = data.get("description", "")

# Transform and predict
X = vectorizer.transform([description])
pred = model.predict(X)[0]
prob = model.predict_proba(X).max()

# Format output
result = {
    "isReal": bool(pred),
    "confidence": round(prob * 100, 2),
    "details": f"Prediction based on {len(description.split())} words"
}

print(json.dumps(result))