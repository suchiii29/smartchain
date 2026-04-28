# 🚛 SmartChain AI
### Resilient Logistics and Dynamic Supply Chain Optimization

> Built for AntiGravity Hackathon 2026 — Smart Supply Chains Track
> Powered by Gemini 1.5 Pro · RandomForest ML · Flutter Web · Firebase

[![Live Demo](https://img.shields.io/badge/Live-Demo-blue)](https://smartchain-project.web.app)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-green)](https://github.com/suchiii29/smartchain)

---

## 🔥 The Problem

Every year, over **$1.5 Trillion** is lost globally due to supply chain disruptions.

A shipment leaves Mumbai. Somewhere near Pune, a highway floods. 
The carrier finds out 6 hours later. The warehouse waits. 
The customer complains. The business loses money.

**87% of disruptions are identified ONLY after delivery 
timelines are already compromised.**

Current tools react. **SmartChain AI predicts.**

---

## 💡 Our Solution

SmartChain AI is a real-time agentic platform that:
- **Predicts** disruptions 72 hours before they happen
- **Analyzes** live weather + traffic + ML predictions simultaneously
- **Recommends** optimized alternate routes using Gemini AI
- **Notifies** drivers instantly with offline-capable alerts
- **Saves** every decision transparently to Firebase

---

## 🏗️ Architecture
Real Weather (OpenWeather API)
↓
ML Models (RandomForest + GradientBoosting)
↓
Gemini 1.5 Pro AI Analysis
↓
MCP Tool Calling Layer
↓
Firebase Realtime Database
↓
Manager Dashboard + Driver Alert

---

## 🎯 Key Features

### Manager Portal
- Real-time AI disruption analysis
- Step-by-step pipeline visualization
- ₹ cost impact per disruption
- One-click route optimization
- Driver status monitoring
- Firebase audit trail

### Driver Portal
- Offline-capable route display
- Real weather alerts (OpenWeather)
- Accept/reject rerouting
- Emergency SOS button
- Auto deviation detection

### Analytics
- 4 real ML models running
- RandomForest: 22.46 min MAE
- GradientBoosting: 67% accuracy
- LogisticRegression: 90.5% accuracy
- IsolationForest anomaly detection
- Feature importance visualization

### Additional Features
- 72-hour disruption forecast
- Carbon footprint tracking
- AI decision audit trail
- Route map with live status

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter Web |
| AI/LLM | Gemini 1.5 Pro |
| ML Models | scikit-learn (Python) |
| Weather | OpenWeather API |
| Database | Firebase Realtime DB |
| Hosting | Firebase Hosting |
| ML Hosting | Render.com |
| Maps | flutter_map + OpenStreetMap |
| Charts | fl_chart |
| Protocol | MCP Tool Calling |

---

## 📊 ML Models

All models trained on 2,000 synthetic samples
based on real Indian logistics patterns.

| Model | Type | Performance |
|-------|------|-------------|
| RandomForestRegressor | Regression | MAE: 22.46 min |
| GradientBoostingClassifier | Classification | 67% accuracy |
| LogisticRegression | Binary Classification | 90.5% accuracy |
| IsolationForest | Anomaly Detection | 10% contamination |

**Top predictive features:**
1. Weather Index (0.22)
2. Port Congestion (0.18)
3. Distance km (0.15)
4. Monsoon Season (0.13)
5. Traffic Level (0.11)

---

## 📚 Research Gaps Addressed

| Research Paper | Gap | Our Solution |
|---------------|-----|-------------|
| Saruchera et al. 2024 | Early warnings missing | 72-hour forecast ✅ |
| DEMATEL Study 2026 | Network collaboration weak | Manager + Driver portal ✅ |
| Zhao et al. 2020 | SME accessibility | Free tier + simple UI ✅ |
| Fatarachian 2020 | Sustainability lacking | Carbon tracker ✅ |
| Zelbst et al. 2019 | Transparency missing | AI audit trail ✅ |

---

## 🚀 How To Run

### Prerequisites
- Flutter SDK 3.5+
- Python 3.10+
- Node.js 18+

### Run Locally
```bash
# Terminal 1 - ML Service
cd ml_service
pip install -r requirements.txt
python app.py

# Terminal 2 - MCP Server
cd mcp_server
npm install
node index.js

# Terminal 3 - Flutter App
flutter pub get
flutter run -d chrome --web-port 8080
```

### Live Demo
Visit: https://smartchain-project.web.app

---

## 🔗 Links

- **Live App:** https://smartchain-project.web.app
- **GitHub:** https://github.com/suchiii29/smartchain
- **ML Service:** https://smartchain-2.onrender.com
