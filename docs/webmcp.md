# WebMCP Implementation

## What is WebMCP?
From the Hack2Skill 2026 Presentation ("The Agentic Handshake"), WebMCP (Web Model Context Protocol) lets AI agents talk DIRECTLY to websites.
It completely eliminates the need for screen scraping.

## ROI Metrics
- **98% Task Accuracy** (eliminates guesswork, compared to 70% with vision-based models)
- **89% Token Savings** (no vision model costs)
- **67.6% Overhead Reduction** (skips DOM tree processing)

## Why This Matters for Hackathon Judges
Implementing WebMCP provides a seamless bridge for AI agents to understand the app's state and context without any brittle hacks. It natively exposes deterministic tools to Large Language Models.

### Comparison: Screen Scraping vs WebMCP
* **Screen Scraping:** High failure rate, breaks on UI updates, expensive vision models.
* **WebMCP:** Zero-fluff JSON RPC via the navigator, 98% accuracy on task execution.

## Testing WebMCP Tools in Browser
1. Run local web server: `flutter run -d web-server --web-port=8080`
2. Open Browser Console (F12)
3. Upon initialization, you should see:
   - `✅ WebMCP Tools Registered:` with a list of Tools
   - ROI Metrics logged
4. An `agentInvoked` listener will capture and log interactions triggered by the agent.
