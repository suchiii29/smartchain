import pandas as pd
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS
from sklearn.ensemble import RandomForestRegressor, IsolationForest
from sklearn.model_selection import train_test_split
import random

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

# Global state for models
delay_model = None
anomaly_model = None
is_trained = False

def generate_mock_data(n_rows=500):
    """Generates synthetic supply chain data for training."""
    data = []
    for _ in range(n_rows):
        distance = random.uniform(50, 2000)
        weather = random.uniform(0, 10)
        traffic = random.uniform(0, 10)
        time_of_day = random.randint(0, 23)
        day_of_week = random.randint(0, 6)
        monsoon = 1 if random.random() < 0.3 else 0
        congestion = 1 if random.random() < 0.2 else 0
        
        # Base delay logic
        # 0.1 mins per km + penalties for weather, traffic, etc.
        delay = (distance * 0.1) + (weather * 15) + (traffic * 10) + (monsoon * 90) + (congestion * 120)
        # Add some noise
        delay += random.uniform(-20, 20)
        if delay < 0: delay = 0
        
        data.append([distance, weather, traffic, time_of_day, day_of_week, monsoon, congestion, delay])
    
    return pd.DataFrame(data, columns=[
        'distance_km', 'weather_score', 'traffic_score', 
        'time_of_day', 'day_of_week', 'is_monsoon_season', 
        'port_congestion', 'actual_delay_minutes'
    ])

def train_models():
    """Initializes and trains the ML models."""
    global delay_model, anomaly_model, is_trained
    print("Generating mock training data...")
    df = generate_mock_data(500)
    
    X = df.drop('actual_delay_minutes', axis=1)
    y = df['actual_delay_minutes']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    print("Training RandomForestRegressor for delay prediction...")
    delay_model = RandomForestRegressor(n_estimators=100, random_state=42)
    delay_model.fit(X_train, y_train)
    
    print("Training IsolationForest for anomaly detection...")
    anomaly_model = IsolationForest(contamination=0.1, random_state=42)
    anomaly_model.fit(X)
    
    is_trained = True
    print("Models trained and ready.")

@app.route('/predict-delay', methods=['POST'])
def predict_delay():
    if not is_trained:
        return jsonify({"error": "Models not trained"}), 500
    
    data = request.json
    try:
        # Features: distance_km, weather_score, traffic_score, time_of_day, day_of_week, monsoon, congestion
        # We'll fill missing ones with defaults for the mock
        features = [
            data.get('distance_km', 500),
            data.get('weather_score', 5),
            data.get('traffic_score', 5),
            data.get('time_of_day', 12),
            data.get('day_of_week', 2),
            data.get('is_monsoon_season', 0),
            data.get('port_congestion', 0)
        ]
        
        prediction = delay_model.predict([features])[0]
        
        # Confidence calculation (mock)
        confidence = 0.85 + (random.random() * 0.1)
        
        # Risk level logic
        risk_level = "low"
        if prediction > 240: risk_level = "critical"
        elif prediction > 120: risk_level = "high"
        elif prediction > 60: risk_level = "medium"
        
        return jsonify({
            "predicted_delay_minutes": round(prediction, 1),
            "confidence": round(confidence, 2),
            "risk_level": risk_level,
            "route": data.get('route', 'Unknown')
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/risk-score', methods=['POST'])
def risk_score():
    data = request.json
    try:
        delays = data.get('historical_delays', [])
        if not delays:
            return jsonify({"risk_score": 0, "category": "low"})
        
        avg_delay = sum(delays) / len(delays)
        variance = np.var(delays) if len(delays) > 1 else 0
        
        # Simple weighted score: 70% average delay impact, 30% volatility
        score = (avg_delay * 0.5) + (np.sqrt(variance) * 0.5)
        score = min(score, 100)
        
        category = "low"
        if score > 80: category = "critical"
        elif score > 50: category = "high"
        elif score > 25: category = "medium"
        
        return jsonify({
            "route": data.get('route', 'Unknown'),
            "risk_score": round(score, 2),
            "category": category
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/anomalies', methods=['GET'])
def get_anomalies():
    # Return 3 mock anomalous routes based on lower anomaly scores
    anomalous_routes = [
        {"route": "JNPT Port -> Bhiwandi", "anomaly_score": -0.72, "reason": "Sudden 400% spike in wait time"},
        {"route": "Kolkata -> Siliguri", "anomaly_score": -0.65, "reason": "Unusual night-time traffic pattern detected"},
        {"route": "Delhi -> Manesar", "anomaly_score": -0.58, "reason": "Route deviation from standard GPS fence"}
    ]
    return jsonify(anomalous_routes)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "status": "ok",
        "models_loaded": is_trained
    })

if __name__ == '__main__':
    train_models()
    app.run(host='0.0.0.0', port=5000)
