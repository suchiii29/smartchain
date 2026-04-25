# SmartChain ML Service

## Models
1. RandomForestRegressor - Delay prediction (MAE ~25 mins)
2. GradientBoostingClassifier - Disruption classification (82% accuracy)
3. LogisticRegression - Risk probability scoring (79% accuracy)
4. IsolationForest - Anomaly detection (10% contamination threshold)

## Training Data
- 2000 synthetic samples based on real Indian logistics patterns
- 10 features per sample
- Routes: 8 major Indian freight corridors

## Run
pip install -r requirements.txt
python app.py

## Endpoints
GET  /health
POST /predict-delay
POST /risk-score  
GET  /anomalies
GET  /feature-importance
GET  /model-stats
