# 🚛 SmartChain AI
### Intelligent Supply Chain Disruption Detection & Route Optimization

> Built for AntiGravity Hackathon 2026 — Smart Supply Chains Track  
> Powered by Gemini 1.5 Pro · MCP Tool Calling · Flutter Web · scikit-learn

---

## 🔥 The Problem

Every year, over **$1.5 Trillion** is lost globally due to supply chain disruptions.

A shipment leaves Mumbai. Somewhere near Pune, a highway floods. The carrier finds out 6 hours later. The warehouse waits. The customer complains. The business loses money.

**Current tools tell you AFTER the damage is done.**

We built SmartChain AI to change that.

---

## 💡 Our Solution

SmartChain AI is a real-time agentic platform that:
- **Predicts** disruptions before they happen (up to 72 hours in advance)
- **Analyzes** live supply chain conditions via MCP tool calling
- **Recommends** optimized alternate routes using Gemini AI
- **Tracks** carbon footprint across your entire fleet
- **Logs** every AI decision transparently in an audit trail

The key difference? **We predict. We don't just react.**

---

## 🏗️ Architecture

SmartChain AI operates as a distributed system designed for scale and heavy-duty reasoning:

1.  **Agentic UI (Flutter)**: A Material 3 dashboard that doesn't just display data—it's **WebMCP-ready**, meaning AI agents can "read" and interact with the interface through structured context.
2.  **ML Microservice (Python/Flask)**: A dedicated scikit-learn server that uses **Random Forest Regressors** for delay prediction and **Isolation Forests** for anomaly detection. It trains on the fly to adapt to local logistics patterns.
3.  **The Gemini Brain**: All raw data from the ML service and live conditions (weather, traffic, port congestion) are piped into **Gemini 1.5 Pro**. It uses reasoning to determine IF a predicted delay warrants a route change and HOW to execute it.
4.  **Sustainability Core**: Integrated carbon tracking that calculates kg CO₂ based on vehicle type (truck/rail/air) and distance, pushing for green-first logistics.

---

## 🛠️ Tech Stack

- **Frontend**: Flutter Web (Dart)
- **Microservices**: Python 3.9+, Flask, Scikit-Learn, Pandas
- **AI Model**: Google Gemini 1.5 Pro
- **Protocol**: WebMCP (Web Model Context Protocol)
- **Analytics**: FL Chart
- **Environment**: Container-ready & Shell-scripted for rapid deployment

---

## 🚀 Impact

By shifting from reactive firefighting to proactive AI-driven forecasting, SmartChain AI helps logistics managers cut delays by an estimated **15-20%** and reduce unnecessary carbon emissions by optimizing for the most efficient vehicle types before a bottleneck even occurs.

---

*“Turning supply chain chaos into a predictable science.”*
