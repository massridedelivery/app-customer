# WebSocket Integration Guide

This document describes how to integrate your customer/driver application with the `driver-backend` WebSocket API for real-time updates (location tracking, job offers, status changes).

## 1. Connection Details

- **URL**: `ws://localhost:8080/ws?token=<YOUR_JWT_TOKEN>`
- **Authentication**: The JWT token must be passed as a query parameter named `token`.
- **Protocol**: Standard WebSocket (ws/wss).

> [!IMPORTANT]
> The server uses the `token` to identify your user ID and role. Ensure the token is valid and not expired.

## 2. Message Format

All messages are sent and received as **JSON strings**.

### Base Message Structure

```json
{
  "type": "string",
  "data": { ... } // Optional payload depending on type
}
```

---

## 3. Client-to-Server Messages (Outgoing)

### Driver: Location Update

Drivers must send their location periodically to stay "discoverable" for jobs.

```json
{
  "type": "location_update",
  "lat": 13.7563,
  "lng": 100.5018
}
```

### Driver: Accept/Reject Job

When a `job_offer` is received, the driver sends one of these:

```json
// Accept
{
  "type": "accept_job",
  "job_id": "uuid-here"
}

// Reject
{
  "type": "reject_job",
  "job_id": "uuid-here"
}
```

---

## 4. Server-to-Client Messages (Incoming)

### For Drivers: Job Offer

Triggered when a customer creates a job near you.

```json
{
  "type": "job_offer",
  "job": {
    "id": "uuid",
    "pickup_lat": 13.7,
    "pickup_lng": 100.5,
    "fare": 150.0,
    ...
  }
}
```

### For Everyone: Job Status Update

Triggered when a job's state changes (ACCEPTED, PICKED_UP, COMPLETED, CANCELLED).

```json
{
  "type": "job_status",
  "job_id": "uuid",
  "status": "PICKED_UP"
}
```

### For Customers: Driver Location

Received while you have an active job. Used to animate the driver's car on your map.

```json
{
  "type": "driver_location",
  "data": {
    "lat": 13.7563,
    "lng": 100.5018
  }
}
```

---

## 5. Troubleshooting & Best Practices

1. **Keep-Alive**: The server may close idle connections. Implement a "Heartbeat" (Ping/Pong) if your client library doesn't handle it automatically.
2. **Reconnection Logic**:
   - If the WebSocket closes (`onclose`), implement an exponential backoff strategy to reconnect.
   - Re-check if the JWT token is still valid before reconnecting.
3. **State Management**:
   - Store the `activeJobID` locally (e.g., `localStorage`).
   - On page load/reconnect, call `GET /api/customer/jobs/active` to sync the current state in case you missed a message.
4. **CORS/CSP**: If you are running a web client, ensure your `Content-Security-Policy` allows `connect-src` to your backend URL.
