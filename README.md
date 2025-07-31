# 🛰️ Dart Log Server

This project provides a lightweight **WebSocket server built with Dart**, designed to support **real-time logging** from any frontend or backend services (e.g. Flutter apps, backend APIs, monitoring agents).

It acts as a **log relay service**, receiving JSON-formatted log data via WebSocket, forwarding it to [Grafana Loki](https://grafana.com/oss/loki/), and optionally broadcasting logs to all connected clients for real-time monitoring and debugging.

---

## 💡 Use Cases

- Forward logs from multiple clients (apps, services, IoT) to **Loki**
- Monitor **real-time logs** in a custom frontend (e.g. Flutter/Dart web)
- Build a **lightweight internal logging platform** without full Grafana UI
- Support **structured logging** with levels (`info`, `warn`, `error`) and sources (`app`, `backend`, etc.)

---

## 🔗 Log Message Format

Logs sent via WebSocket must be in **JSON format**:

```json
{
  "level": "info",
  "source": "app",
  "message": "User logged in",
  "route": "/login"
}
```
---

## 🛠️ Loki Integration

Logs are forwarded to Grafana Loki via its /loki/api/v1/push HTTP endpoint. You can adjust Loki settings or retention policy via its configuration file (e.g. local-config.yaml) to control log rotation or expiration.

---

## ▶️ Run the Server

To start the WebSocket server, run the following command:

```bash
dart run bin/main.dart

loki-windows-amd64.exe --config.file=loki-local-config.yaml
