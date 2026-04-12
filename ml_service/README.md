# SmartChain ML Microservice

This service provides machine learning capabilities for logistics delay prediction and supply chain anomaly detection.

## Prerequisites
- Python 3.9+
- pip

## Setup & Run
1. Navigate to the `ml_service` directory.
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Start the server:
   ```bash
   python app.py
   ```

## Endpoints
- `GET /health`: Check if the models are loaded.
- `POST /predict-delay`: Predict arrival delay for a route based on distance, weather, and traffic.
- `POST /risk-score`: Calculate a cumulative risk score from historical delay data.
- `GET /anomalies`: Fetch detected route or timing anomalies.

The service runs on `http://localhost:5000` by default and has CORS enabled for all origins.
