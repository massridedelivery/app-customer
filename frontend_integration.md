---
title: "Frontend Integration Guide"
sync_to_confluence: true
---

# Frontend Integration Guide

**Last Updated:** March 16, 2026
**Version:** v1.2.0 (Production Optimized)

This document provides an overview of the backend implementation for the Flutter frontend team. It covers the core user flows, REST API expectations, and the WebSocket connection details for **ride-hailing**, **food delivery**, and all production features.

---

## 🔴 Breaking Changes (Must Read)

### 1. Fare Estimate Response Structure Changed

**Endpoint:** `POST /api/customer/jobs/estimate`

Response now includes surge pricing information:

```json
{
  "distance_km": 5.4,
  "duration_min": 12.0,
  "waypoint": "encoded_polyline...",
  "surge_multiplier": 1.5,
  "surge_active": true,
  "surge_message": "High demand in your area",
  "estimations": [
    {
      "vehicle_type_id": "uuid-1",
      "vehicle_type_name": "motorcycle",
      "display_name": "Motorcycle",
      "base_fare": 89.0,
      "surge_multiplier": 1.5,
      "final_fare": 133.5,
      "discount": 0,
      "total_fare": 133.5
    }
  ]
}
```

**Action Required:**

- Update UI to show surge indicator when `surge_active: true`
- Display `final_fare` instead of `base_fare` during surge
- Show surge message to users
- Surge multiplier capped at 2.5x

---

### 2. Cancellation Response Includes Fees

**Endpoint:** `POST /api/customer/jobs/:id/cancel`

Response now includes cancellation fee information:

```json
{
  "job_id": "uuid",
  "status": "cancelled",
  "cancellation_fee": 20.0,
  "fee_waived": false,
  "cancellations_today": 2
}
```

**Action Required:**

- Show fee warning before confirming cancellation
- Display "First cancellation free today" when `cancellations_today < 2`
- Show 20 THB fee for 2nd+ cancellations
- Fee charged via wallet ledger (not immediate card charge)

---

### 3. Driver Profile Includes Documents

**Endpoint:** `GET /api/driver/profile`

Response now includes document verification status:

```json
{
  "user_id": "uuid",
  "verified": true,
  "documents": [
    {
      "type": "id_card",
      "status": "approved|pending|rejected",
      "media_url": "https://...",
      "reviewed_at": "2026-03-01T10:00:00Z",
      "rejection_reason": "Document unclear"
    }
  ],
  "incentive_tier": "BRONZE",
  "acceptance_rate": 95.5,
  "weekly_completed_jobs": 15,
  "vehicle_types": [...]
}
```

**Action Required (Driver App):**

- Add document upload screen (4 documents required)
- Show status badges for each document
- Block "Go Online" if any document not `approved`
- Display incentive tier badge (BRONZE/SILVER/GOLD)

---

### 4. Admin Routes Require Admin Role

All `/api/admin/*` endpoints now require `role: "admin"` in JWT token.

**Action Required:**

- Ensure admin users have correct role
- Handle 403 Forbidden for non-admin users

---

### 5. Multi-Stop Ride Integration

Frontends must handle multiple coordinates and stop-specific statuses.

**Status Flow Updates:**

1. **Request Phase**: Allow users to add up to 3 intermediate waypoints. Send as `stops` array in `POST /api/customer/jobs`.
2. **Pickup Phase**: New status `ARRIVED_AT_PICKUP` requires UI to distinguish between reaching the customer and starting the trip.
3. **Trip Phase**: While `PICKED_UP`, the driver app must cycle through `arrive` and `depart` actions for each waypoint in sequence.

**WebSocket Handling**:
Listeners must subscribe to `stop_status` messages to update stop markers (e.g., turning a pin green when arrived).

---

### 6. NEW: Loyalty & Subscription Features

**Customer-facing endpoints:**

- `GET /api/customer/loyalty` - Points balance, tier, cashback rate
- `GET /api/customer/loyalty/history` - Point transactions
- `POST /api/customer/loyalty/redeem` - Redeem points for promo vouchers
- `POST /api/customer/loyalty/subscribe` - Subscribe to PRO tier (Plans: `PRO_MONTHLY`, `PRO_YEARLY`)
- `GET /api/customer/loyalty/referral` - Get referral code

**PRO Subscription Benefits:**

- -20 THB discount on every delivery
- 1.5x points earning rate
- Exclusive vouchers
- Priority support

**Action Required:**

- Add loyalty dashboard showing points and tier
- Display PRO subscription benefits and pricing
- Show referral code sharing UI
- Add points redemption catalog

---

### 7. NEW: Corporate Billing

**For corporate employees:**

- `GET /api/corporate/status` - Check corporate membership
- `POST /api/customer/jobs` with `payment_method: "CORPORATE"`

**Features:**

- Employee monthly spending limits
- Corporate credit limits
- Monthly invoicing with 7% VAT

**Action Required:**

- Add corporate payment option for eligible users
- Show spending limit remaining
- Display corporate billing history

---

### 8. NEW: Feature Flags

**Endpoint:** `GET /api/config/flags`

Returns enabled feature flags for the current user:

```json
{
  "flags": [
    {
      "key": "multi_tier_delivery",
      "enabled": true
    },
    {
      "key": "loyalty_program",
      "enabled": true
    },
    {
      "key": "venue_pin_snap",
      "enabled": true
    }
  ]
}
```

**Action Required:**

- Call on app launch to check available features
- Respect feature switches for UI visibility (e.g., don't show "Venues" if `venue_pin_snap` is disabled).

---

### 9. NEW: Venue Pin Snapping (Safe Pickups)

When a customer moves their pickup pin, the app should check if the location is within a geofenced venue (e.g., Suvarnabhumi Airport).

**Endpoint:** `POST /api/geospatial/check-venue`

**Request:**
```json
{
  "lat": 13.6898,
  "lng": 100.7501
}
```

**Response (In Venue):**
```json
{
  "is_in_venue": true,
  "venue": {
    "id": "venue-uuid",
    "name": "Suvarnabhumi Airport (BKK)",
    "venue_type": "AIRPORT"
  },
  "pickup_points": [
    {
      "id": "pt-1",
      "name": "Gate 3, Level 2",
      "lat": 13.6899,
      "lng": 100.7502
    },
    {
      "id": "pt-2",
      "name": "Gate 4, Level 2",
      "lat": 13.6901,
      "lng": 100.7505
    }
  ],
  "message": "Please select a predefined pickup point for this venue."
}
```

**Action Required:**
- If `is_in_venue` is true, show the list of `pickup_points`.
- User **must** select one of these points to proceed.
- Use the selected point's `lat/lng` for the job request.
8. **Pickup + Delivery:** Driver calls `picked-up` → `delivered`. Status: `DRIVER_PICKED_UP` → `DELIVERED`. Customer receives real-time status updates via WS.
9. **Track Order:** Customer can poll `GET /api/food/customer/orders/:id` or listen for WS status events.

### E. Food Delivery Flow (Restaurant Dashboard)

1. **Setup Profile:** Restaurant calls `PUT /api/food/restaurant/profile` to set name, address, cuisine type, etc.
2. **Manage Menu:** Create categories (`POST /api/food/restaurant/menu/categories`) and items (`POST /api/food/restaurant/menu/items`).
3. **Go Open:** Restaurant calls `POST /api/food/restaurant/open` with `{"is_open": true}` to start accepting orders.
4. **Receive Orders:** Orders arrive via WebSocket (`new_food_order` message). Also visible via `GET /api/food/restaurant/orders/pending`.
5. **Process Orders:** Accept → Mark Preparing → Mark Ready for Pickup. Each status change notifies the customer via WS.

### F. Food Delivery Flow (Driver)

1. **Receive Offers:** While online, drivers receive `food_delivery_offer` messages via WebSocket for nearby orders.
2. **Accept Delivery:** Driver calls `POST /api/food/driver/orders/:id/accept`. Subject to capacity check (Phase 1: max 1 active food order).
3. **Pickup + Deliver:** Driver calls `POST /api/food/driver/orders/:id/picked-up` then `POST /api/food/driver/orders/:id/delivered`.
4. **Active Orders:** Driver can check `GET /api/food/driver/orders/active` to see current food deliveries.

### G. Promotions & Credit Cards Flow

1. **Save Card:** Customer enters card details (via Omise SDK on Flutter). Flutter gets `card_token`. Call `POST /api/payment/card` to save.
2. **Validate Promo:** Customer enters a coupon code. App calls `GET /api/customer/promo/validate?code=XYZ`. Backend returns discount amount.
3. **Request with Promo:** Customer calls `POST /api/customer/jobs` with `payment_method: "CARD"` and `promo_code: "XYZ"`.

---

## 2. Request / Response Standards

- **Base URL:** `http://localhost:8080` (or `http://10.0.2.2:8080` for Android Emulator)
- **Content-Type:** `application/json` (except `/api/driver/documents` which is `multipart/form-data`)
- **Authentication:** `Authorization: Bearer <access_token>`
- **Full API Docs (Swagger):** Run the backend and visit `http://localhost:8080/swagger/`

### Common Structure

**Success (2xx):**
Returns the requested JSON object or an array.

```json
{
  "id": "u-123",
  "full_name": "John Doe",
  "phone": "+66123456789"
}
```

**Error (4xx/5xx):**
Always returns an `error` key with a human-readable message.

```json
{
  "error": "invalid otp code"
}
```

**Rate Limited (429):**

```json
{
  "error": "Too Many Requests"
}
```

---

## 3. WebSocket Connection

The WebSocket connection is crucial for the real-time ride flow. Both Customers and Drivers use the same WebSocket endpoint.

- **Endpoint:** `ws://<host>/ws`
- **Authentication:** Pass the token as a query parameter: `?token=<access_token>`

### Message Format (JSON)

All messages sent to and received from the WebSocket use this structure:

```json
{
  "type": "string",
  ...fields depending on type
}
```

### A. Messages the App sends to Backend (Upstream)

1. **Driver Location Update:**
   Sent by the Driver app every few seconds while online.

```json
{
  "type": "location_update",
  "lat": 13.7563,
  "lng": 100.5018
}
```

2. **Driver Accept Job:**

```json
{
  "type": "accept_job",
  "job_id": "uuid-here"
}
```

3. **Driver Reject Job:**

```json
{
  "type": "reject_job",
  "job_id": "uuid-here"
}
```

4. **Update Job Status (Driver):**
   Allowed statuses: `ARRIVED_AT_PICK_UP`, `PICKED_UP`, `COMPLETED`, `CANCELLED`

```json
{
  "type": "job_status",
  "job_id": "uuid-here",
  "status": "COMPLETED"
}
```

### B. Messages the Backend sends to App (Downstream)

1. **Job Offer (To Driver):**
   When a customer requests a ride nearby. Includes the full job object with fare and vehicle type info.

```json
{
  "type": "job_offer",
  "job": {
    "id": "uuid-here",
    "pickup_lat": 13.7,
    "pickup_lng": 100.5,
    "dropoff_lat": 13.8,
    "dropoff_lng": 100.55,
    "pickup_address": "Siam Paragon",
    "dropoff_address": "Chatuchak",
    "fare": 150.0,
    "distance_km": 5.4,
    "status": "PENDING",
    "payment_method": "CASH"
  }
}
```

2. **Job Accepted (To Customer + Driver):**

```json
{
  "type": "job_accepted",
  "job": {
    "id": "uuid",
    "status": "ACCEPTED",
    "driver_id": "uuid"
  }
}
```

3. **Driver Location Stream (To Customer):**
   Live GPS updates of the assigned driver.

```json
{
  "type": "driver_location",
  "lat": 13.7563,
  "lng": 100.5018
}
```

4. **Job Status Changed (To Both):**
   Sent when a job's state changes (ACCEPTED, ARRIVED_AT_PICK_UP, PICKED_UP, COMPLETED, CANCELLED).

```json
{
  "type": "job_status",
  "job_id": "uuid-here",
  "status": "ARRIVED_AT_PICK_UP"
}
```

5. **Error Message:**

```json
{
  "type": "error",
  "error": "job already taken"
}
```

---

## 4. Important Remarks

1. **Driver Location API vs WS:** The backend supports `POST /api/driver/location` as an alternative to the WebSocket `location_update`. The WebSocket is more efficient for battery and bandwidth during an active ride.
2. **Ping/Pong:** The backend sends a standard WebSocket `PING` every ~54 seconds. Ensure your WebSocket library handles Keep-Alives.
3. **Reconnection:** Mobile networks drop frequently. Implement exponential backoff reconnection and resync state by calling `GET /api/driver/jobs/active` or `GET /api/customer/jobs/active`.

---

## 5. REST API Endpoint Reference

### Authentication API (Public)

#### `POST /auth/otp/send`

- **Request:** `{"phone": "+66...", "role": "customer" | "driver" | "restaurant"}`
- **Response:** `{"status": "pending"}`

#### `POST /auth/otp/verify`

- **Request:** `{"phone": "+66...", "code": "123456", "role": "customer" | "driver" | "restaurant", "full_name": "New User"}`
- **Response:** `{"access_token": "...", "refresh_token": "...", "expires_in": 86400}`

#### `POST /auth/register` (Alternative to OTP)

- **Request:** `{"email": "...", "password": "...", "role": "customer" | "driver" | "restaurant", "full_name": "..."}`
- **Response:** `{"id": "...", "email": "..."}`

#### `POST /auth/login` (Alternative to OTP)

- **Request:** `{"email": "...", "password": "..."}`
- **Response:** `{"access_token": "...", "refresh_token": "...", "expires_in": 86400}`

---

### Vehicle Type API (Requires Bearer Token)

#### `GET /api/vehicle-types?active_only=true`

Returns list of all vehicle types with pricing.

**Response:**

```json
[
  {
    "id": "uuid-1",
    "name": "motorcycle",
    "display_name": "Motorcycle",
    "description": "Fast and affordable motorcycle taxi",
    "base_fare": 30.0,
    "price_per_km": 10.0,
    "price_per_min": 1.5,
    "min_fare": 30.0,
    "is_active": true
  },
  {
    "id": "uuid-2",
    "name": "car_economy",
    "display_name": "Economy Car",
    "base_fare": 35.0,
    "price_per_km": 12.0,
    "price_per_min": 2.0,
    "min_fare": 35.0,
    "is_active": true
  }
]
```

#### `GET /api/vehicle-types/:id`

Returns details of a specific vehicle type.

#### `POST /api/vehicle-types` (Admin)

- **Request:** `{"name": "suv", "display_name": "SUV", "base_fare": 60, "price_per_km": 18, "price_per_min": 2.5, "min_fare": 60}`

#### `PUT /api/vehicle-types/:id` (Admin)

- **Request:** Partial update — any subset of fields.

#### `DELETE /api/vehicle-types/:id` (Admin)

---

### Customer API (Requires Bearer Token)

#### `GET /api/customer/profile`

- **Response:** `{"user_id": "...", "full_name": "...", "phone": "...", "rating": 5.0}`

#### `PUT /api/customer/profile`

- **Request:** `{"full_name": "Updated Name", "emergency_contact": "...", "preferences": {"quiet_ride": true}}`

#### `GET /api/customer/places`

- **Response:** `[{"id": "...", "name": "Work", "lat": 1.2, "lng": 3.4}]`

#### `POST /api/customer/places`

- **Request:** `{"name": "...", "lat": 12.34, "lng": 45.67}`

#### `POST /api/customer/jobs/estimate` (Estimate Fare)

Returns fare estimates. If `vehicle_type_id` is provided, returns one estimate. If omitted, returns estimates for **all** active vehicle types.

- **Request:**
  ```json
  {
    "pickup_lat": 13.75,
    "pickup_lng": 100.5,
    "dropoff_lat": 13.78,
    "dropoff_lng": 100.55,
    "promo_code": "DISCOUNT50",
    "vehicle_type_id": "uuid-1"
  }
  ```
- **Response:**
  ```json
  {
    "distance_km": 5.4,
    "duration_min": 12.0,
    "waypoint": "encoded_polyline...",
    "estimations": [
      {
        "vehicle_type_id": "uuid-1",
        "vehicle_type_name": "motorcycle",
        "display_name": "Motorcycle",
        "base_fare": 89.0,
        "discount": 0,
        "total_fare": 89.0
      },
      {
        "vehicle_type_id": "uuid-2",
        "vehicle_type_name": "car_economy",
        "display_name": "Economy Car",
        "base_fare": 123.8,
        "discount": 0,
        "total_fare": 123.8
      }
    ]
  }
  ```

#### `POST /api/customer/jobs` (Request a Ride)

**`vehicle_type_id` is required.** The fare is calculated server-side using the vehicle type's pricing.

- **Request:**
  ```json
  {
    "pickup_lat": 13.75,
    "pickup_lng": 100.5,
    "pickup_address": "Siam Paragon",
    "dropoff_lat": 13.78,
    "dropoff_lng": 100.55,
    "dropoff_address": "Chatuchak",
    "vehicle_type_id": "uuid-2",
    "payment_method": "CASH",
    "promo_code": "DISCOUNT50"
  }
  ```
- **Response:** `{"id": "job-uuid", "status": "PENDING", "fare": 123.80, "discount": 50.0, ...}`

#### `GET /api/customer/jobs/:id`

- **Response:** Returns job details.

#### `GET /api/customer/jobs/active`

- **Response:** Returns current active job or 404.

#### `POST /api/customer/jobs/:id/cancel`

- **Response:** `{"message": "job cancelled"}`

#### `POST /api/customer/jobs/:id/rate`

- **Request:** `{"rating": 5, "comment": "Great ride"}`
- **Response:** `200 OK`

#### `GET /api/customer/promo/validate?code=XYZ`

- **Response:** `{"code": "DISCOUNT50", "discount_type": "flat", "discount_value": 50.0, "valid": true}`

#### `GET /api/customer/promo/list`

- **Response:** Returns active promotions.

#### `POST /api/payment/card` (Save card)

- **Request:** `{"card_token": "tokn_test_...", "email": "user@example.com"}`
- **Response:** `{"message": "card saved successfully"}`

---

### Driver API (Requires Bearer Token)

#### `GET /api/driver/profile`

**Response:**

```json
{
  "user_id": "uuid",
  "full_name": "John Doe",
  "phone": "+66812345678",
  "rating": 4.8,
  "total_trips": 50,
  "is_verified": true,
  "vehicle_type_ids": ["uuid-1", "uuid-2"],
  "vehicle_class": "car",
  "vehicle_types": [
    {
      "id": "uuid-1",
      "name": "car_economy",
      "display_name": "Economy Car",
      "is_enabled": true
    },
    {
      "id": "uuid-2",
      "name": "car_comfort",
      "display_name": "Comfort Car",
      "is_enabled": false
    }
  ],
  "vehicle_plate": "กข 1234",
  "vehicle_color": "Silver",
  "vehicle_model": "Camry",
  "vehicle_year": 2020,
  "vehicle_province": "Bangkok",
  "balance": 1500.0,
  "commission_rate": 0.2,
  "status": "offline"
}
```

#### `PUT /api/driver/profile`

- **Request:**
  ```json
  {
    "full_name": "John Doe",
    "vehicle_type_ids": ["uuid-1", "uuid-2"],
    "vehicle_plate": "กข 1234",
    "vehicle_color": "Silver",
    "vehicle_model": "Camry",
    "vehicle_year": 2020,
    "vehicle_province": "Bangkok"
  }
  ```

#### `POST /api/driver/online`

- **Response:** `{"status": "online"}`

#### `POST /api/driver/offline`

- **Response:** `{"status": "offline"}`

#### `POST /api/driver/location`

- **Request:** `{"lat": 13.75, "lng": 100.50}`
- **Response:** `{"status": "location updated"}`

#### `GET /api/driver/jobs/active`

- **Response:** Returns the current active job or 404.

#### `POST /api/driver/jobs/:id/accept`

- **Response:** `{"message": "job accepted"}`

#### `PATCH /api/driver/jobs/:id/status`

- **Request:** `{"status": "ARRIVED_AT_PICK_UP" | "PICKED_UP" | "COMPLETED" | "CANCELLED"}`
- **Response:** `{"message": "job status updated"}`

#### `GET /api/driver/earnings`

- **Response:** `{"balance": 1500.0, "total_trips": 12}`

#### `GET /api/driver/earnings/trips?page=1&limit=10`

- **Response:** `{"data": [...], "page": 1, "limit": 10}`

#### `POST /api/driver/documents`

- **Body:** `multipart/form-data` with `document` (file), `type` ("license", "id_card", "registration"), `doc_number` (optional)

#### `GET /api/driver/documents`

- **Response:** Returns list of driver documents.

#### `PATCH /api/driver/vehicle-types/:id/toggle`

- **Request:** `{"enabled": true}`
- **Response:** `200 OK`
- **Effect:** Immediately updates dispatch eligibility if driver is online.

---

### Food Delivery — Restaurant API (Requires Bearer Token, role: `restaurant`)

#### `GET /api/food/restaurant/profile`

- **Response:**
  ```json
  {
    "user_id": "uuid",
    "restaurant_name": "Pad Thai Palace",
    "description": "Authentic Thai street food",
    "cuisine_type": "Thai",
    "address": "123 Sukhumvit Rd",
    "lat": 13.7563,
    "lng": 100.5018,
    "logo_url": "https://...",
    "cover_image_url": "https://...",
    "rating": 4.8,
    "is_active": true,
    "is_open": false,
    "min_order_amount": 50.0
  }
  ```

#### `PUT /api/food/restaurant/profile`

- **Request:** `{"restaurant_name": "...", "description": "...", "cuisine_type": "...", "address": "...", "lat": 13.75, "lng": 100.50, "min_order_amount": 100.0}`

#### `POST /api/food/restaurant/open`

- **Request:** `{"is_open": true}`
- **Response:** `{"is_open": true}`

#### `GET /api/food/restaurant/orders/pending`

- **Query:** Optional `?status=PLACED,PREPARING` (comma-separated)
- **Response:** Array of food orders.

#### `POST /api/food/restaurant/orders/:id/accept`

- **Response:** `{"status": "RESTAURANT_ACCEPTED"}`

#### `POST /api/food/restaurant/orders/:id/reject`

- **Response:** `{"status": "RESTAURANT_REJECTED"}`

#### `POST /api/food/restaurant/orders/:id/preparing`

- **Response:** `{"status": "PREPARING"}`

#### `POST /api/food/restaurant/orders/:id/ready`

- **Response:** `{"status": "READY_FOR_PICKUP"}`

#### `POST /api/food/restaurant/menu/categories`

- **Request:** `{"name": "Main Course", "sort_order": 1}`
- **Response:** `{"id": "uuid", "restaurant_id": "uuid", "name": "Main Course", "sort_order": 1, "is_active": true}`

#### `GET /api/food/restaurant/menu/categories`

- **Response:** Array of categories.

#### `PUT /api/food/restaurant/menu/categories/:id`

- **Request:** `{"name": "Updated Name", "sort_order": 2, "is_active": false}`

#### `DELETE /api/food/restaurant/menu/categories/:id`

#### `POST /api/food/restaurant/menu/items`

- **Request:**
  ```json
  {
    "category_id": "uuid",
    "name": "Pad Thai",
    "description": "Classic stir-fried noodles",
    "price": 80.0,
    "image_url": "https://...",
    "options": "[{\"name\": \"Spice Level\", \"choices\": [\"Mild\", \"Medium\", \"Hot\"]}]"
  }
  ```

#### `PUT /api/food/restaurant/menu/items/:id`

- **Request:** Partial update — any subset of fields.

#### `DELETE /api/food/restaurant/menu/items/:id`

---

### Food Delivery — Customer API (Requires Bearer Token, role: `customer`)

#### `GET /api/food/customer/restaurants/nearby?lat=13.75&lng=100.50&radius_km=5`

- **Response:** Array of nearby open restaurants with distance.
  ```json
  [
    {
      "user_id": "uuid",
      "restaurant_name": "Pad Thai Palace",
      "cuisine_type": "Thai",
      "rating": 4.8,
      "is_open": true,
      "min_order_amount": 50.0,
      "distance_km": 1.2,
      "has_drivers_nearby": true
    }
  ]
  ```

#### `GET /api/food/customer/restaurants/:id`

- **Response:** Restaurant profile.

#### `GET /api/food/customer/restaurants/:id/menu`

- **Response:** Full menu grouped by category.
  ```json
  {
    "categories": [
      {
        "id": "uuid",
        "name": "Main Course",
        "sort_order": 1,
        "is_active": true,
        "items": [
          {
            "id": "uuid",
            "name": "Pad Thai",
            "description": "Classic stir-fried noodles",
            "price": 80.0,
            "image_url": "https://...",
            "is_available": true
          }
        ]
      }
    ]
  }
  ```

#### `POST /api/food/customer/orders`

- **Request:**
  ```json
  {
    "restaurant_id": "uuid",
    "items": [
      { "menu_item_id": "uuid-1", "quantity": 2 },
      { "menu_item_id": "uuid-2", "quantity": 1 }
    ],
    "delivery_lat": 13.76,
    "delivery_lng": 100.51,
    "delivery_address": "123 My Street",
    "payment_method": "CASH"
  }
  ```
- **Response:**
  ```json
  {
    "id": "order-uuid",
    "status": "PLACED",
    "food_total": 240.00,
    "delivery_fee": 30.00,
    "total_amount": 270.00,
    "items": [...]
  }
  ```
- **Note:** Item prices are always fetched from DB — client prices are ignored.

#### `GET /api/food/customer/orders`

- **Response:** Array of all customer's food orders.

#### `GET /api/food/customer/orders/:id`

- **Response:** Full order details including items.

#### `POST /api/food/customer/orders/:id/cancel`

- **Restriction:** Only allowed while status is `PLACED` (before restaurant accepts).
- **Response:** `{"status": "CANCELLED"}`

---

### Food Delivery — Driver API (Requires Bearer Token, role: `driver`)

#### `GET /api/food/driver/orders/active`

- **Response:** Array of active food delivery orders for the driver.

#### `POST /api/food/driver/orders/:id/accept`

- **Response:** `{"status": "DRIVER_ASSIGNED"}`
- **Errors:** `409` if already taken, `400` if driver at capacity (max 1 active food order in Phase 1).

#### `POST /api/food/driver/orders/:id/picked-up`

- **Response:** `{"status": "DRIVER_PICKED_UP"}`

#### `POST /api/food/driver/orders/:id/delivered`

- **Response:** `{"status": "DELIVERED"}`

---

### Admin API (Requires Bearer Token, role: `admin`)

#### `GET /api/admin/pricing/zones`

- **Response:** Array of all pricing zones (Polygons and H3 hexagons).

#### `POST /api/admin/pricing/zones`

- **Request:**
  ```json
  {
    "name": "Airport Surge",
    "description": "High demand at BKK",
    "boundary": "POLYGON((lng lat, ...))", // Optional: Layer A (Business)
    "h3_index": "88652834b7fffff", // Optional: Layer B (Surge)
    "ride_multiplier": 1.5,
    "food_multiplier": 1.2,
    "ride_surcharge": 20.0,
    "food_surcharge": 10.0,
    "is_active": true
  }
  ```

#### `PUT /api/admin/pricing/zones/:id`

- **Request:** Full or partial update of zone properties.

#### `DELETE /api/admin/pricing/zones/:id`

#### `GET /api/admin/util/h3-index?lat=13.75&lng=100.50`

- **Response:** `{"h3_index": "88652834b7fffff"}`
- **Usage:** Used by the simulator to resolve coordinates to the system's H3 resolution.

---

## 6. Dynamic Pricing Strategy (Dual-Layer)

The backend implements a prioritized "Dual-Layer" pricing lookup for every ride estimate and food order:

1.  **Layer A (Business Polygons):** High-precision zones manually defined by admins. If a pickup location falls inside a polygon, these rules are applied first.
2.  **Layer B (Dynamic H3 Surge):** High-scale hexagonal cells (Resolution 8). If no business polygon matches, the backend checks for an exact H3 cell match (used for algorithmic surge like rain or events).

**Calculations:**
`Final Fare = (Base Fare * Multiplier) + Surcharge`

---

## 7. New Features (Since v1.1.0-dev17)

### A. FCM Push Notifications ✅

**Endpoint:** `POST /api/notifications/register-device`

**Request:**

```json
{
  "device_token": "Firebase-FCM-token",
  "device_type": "ios|android"
}
```

**Notification Types:**

- **Job Offers** (high priority) - Driver receives when new job available
- **Driver Cancelled** (high priority) - Customer notified when driver cancels
- **Document Status** (normal priority) - Driver notified on approval/rejection
- **Chat Messages** (normal priority) - New message notifications

**Integration Steps:**

1. Integrate Firebase SDK in mobile app
2. Request notification permissions on app install
3. Call `/api/notifications/register-device` on every app launch
4. Handle push notifications:
   - Job offer → Navigate to job acceptance screen
   - Driver cancelled → Show message, offer rebooking
   - Document approved → Show success
   - Chat message → Show preview, navigate to chat

---

### B. Scheduled Rides (Book in Advance) ✅

**Endpoint:** `POST /api/customer/jobs/scheduled`

**Request:**

```json
{
  "scheduled_at": "2026-03-05T08:00:00+07:00",
  "pickup_lat": 13.7563,
  "pickup_lng": 100.5018,
  "dropoff_lat": 13.7244,
  "dropoff_lng": 100.4983,
  "vehicle_type": "car",
  "passenger_name": "John Doe",
  "passenger_phone": "+66812345678"
}
```

**Features:**

- Book up to 7 days in advance
- Automatic dispatch 15-30 minutes before scheduled time
- Free cancellation if >1 hour before scheduled time

**UI Requirements:**

- Add "Schedule for Later" option on booking screen
- Date/time picker (max 7 days ahead)
- Show scheduled rides in trip history with indicator

**Related Endpoints:**

- `GET /api/customer/jobs/scheduled` - List my scheduled rides
- `GET /api/customer/jobs/scheduled/:id` - Get details
- `DELETE /api/customer/jobs/scheduled/:id` - Cancel scheduled ride

---

### C. Multi-Stop Rides ✅

**Endpoint:** `POST /api/customer/jobs/multi-stop`

**Request:**

```json
{
  "stops": [
    {
      "sequence": 1,
      "lat": 13.7563,
      "lng": 100.5018,
      "address": "Pickup location",
      "stop_type": "pickup"
    },
    {
      "sequence": 2,
      "lat": 13.7244,
      "lng": 100.4983,
      "address": "Waypoint 1",
      "stop_type": "waypoint"
    },
    {
      "sequence": 3,
      "lat": 13.7308,
      "lng": 100.5214,
      "address": "Final destination",
      "stop_type": "dropoff"
    }
  ],
  "vehicle_type": "car"
}
```

**Features:**

- Support for up to 5 stops (pickup + dropoff + 3 waypoints)
- Fare calculation includes all stops
- Stop types: `pickup`, `dropoff`, `waypoint`

**UI Requirements:**

- Add "Add Stop" button on booking screen
- Allow reordering of stops (drag & drop)
- Show fare breakdown including all stops
- Display multi-stop indicator during trip

---

### D. Driver Document Verification ✅

**Upload Flow:**

1. **Get Presigned URL:** `POST /api/media/upload-url`
   ```json
   {
     "file_type": "image/jpeg",
     "file_size": 1024000,
     "purpose": "driver_document",
     "document_type": "id_card"
   }
   ```
2. **Upload File:** PUT request to `upload_url` (direct to storage)
3. **Confirm Upload:** `POST /api/driver/documents`
   ```json
   {
     "document_type": "id_card",
     "file_key": "uploads/drivers/uuid/timestamp.jpg"
   }
   ```

**Required Documents:**

- `id_card` - National ID card
- `drivers_license` - Driver's license
- `vehicle_registration` - Vehicle registration
- `insurance` - Vehicle insurance

**Features:**

- Document status: `pending → approved → rejected`
- Drivers **BLOCKED** from going online until all documents approved
- FCM notifications on document status changes
- Re-upload allowed if rejected

**UI Requirements (Driver App):**

- Document upload screen with camera integration
- Show status badges: Pending/Approved/Rejected
- Block "Go Online" button if any document not approved
- Show rejection reason if applicable

---

### E. Surge Pricing & Demand Heatmap ✅

**Customer App - Updated Fare Estimate:**

```json
{
  "base_fare": 50.0,
  "distance_km": 5.2,
  "duration_min": 15,
  "surge_multiplier": 1.5,
  "surge_active": true,
  "final_fare": 180.0,
  "surge_message": "High demand in your area - 1.5x fare"
}
```

**Driver App - Demand Heatmap:**

```http
GET /api/driver/demand-heatmap
```

**Response:**

```json
{
  "hexagons": [
    {
      "h3_index": "8a2a1072b59ffff",
      "center_lat": 13.7563,
      "center_lng": 100.5018,
      "demand_count": 15,
      "supply_count": 8,
      "surge_multiplier": 1.5,
      "surge_active": true
    }
  ]
}
```

**UI Requirements (Customer App):**

- Show surge multiplier on fare estimate
- Display colored surge indicator on map
- Show message: "High demand - fares increased by X%"

**UI Requirements (Driver App):**

- Add heatmap overlay on map
- Color-code areas by demand (red = high, green = low)
- Show demand count and surge multiplier per zone

---

### F. Cancellation Fee System ✅

**Customer Cancel:**

```http
POST /api/customer/jobs/:id/cancel
```

**Response:**

```json
{
  "job_id": "uuid",
  "status": "cancelled",
  "cancellation_fee": 20.0,
  "fee_waived": false,
  "cancellations_today": 2
}
```

**Rules:**

- First cancellation per day: **FREE** (goodwill waiver)
- 2nd+ cancellation after driver accepts: **20 THB**
- Fee charged to customer wallet
- Driver receives compensation via wallet ledger

**Driver Cancel:**

```http
POST /api/driver/jobs/:id/cancel
```

**Request:**

```json
{
  "reason": "vehicle_breakdown|customer_unreachable|emergency|long_pickup_time|other"
}
```

**UI Requirements (Customer App):**

- Show cancellation fee warning before confirming
- Display "First cancellation free today" if applicable
- Show 20 THB fee for 2nd+ cancellations

**UI Requirements (Driver App):**

- Add "Cancel Ride" button for accepted/picked-up jobs
- Show reason selector modal (required)
- Customer receives FCM notification about cancellation

---

### G. Driver Earnings & Payouts ✅

**Earnings Summary:**

```http
GET /api/driver/earnings
```

**Response:**

```json
{
  "total_earnings": 15000.0,
  "available_balance": 12000.0,
  "pending_payouts": 3000.0,
  "period": {
    "from": "2026-03-01",
    "to": "2026-03-04"
  },
  "trips_completed": 25
}
```

**Trip Breakdown:**

```http
GET /api/driver/earnings/trips?page=1&limit=10
```

**Request Payout:**

```http
POST /api/driver/payouts
```

**Request:**

```json
{
  "amount": 5000.0,
  "bank_account": {
    "bank_name": "Bangkok Bank",
    "account_number": "1234567890",
    "account_holder": "John Doe"
  }
}
```

**Features:**

- Minimum payout amount: 100 THB
- Admin approval workflow
- Bank account management
- Wallet ledger integration

**UI Requirements:**

- Add "Earnings" tab in driver app
- Show daily/weekly/monthly views
- Display trip-by-trip breakdown
- Add "Request Payout" button with bank form
- Show payout history with status (Pending/Approved/Completed/Failed)

**Related Endpoints:**

- `GET /api/driver/payouts` - List my payout requests
- `GET /api/admin/payouts` - List all payouts (Admin only)
- `POST /api/admin/payouts/:id/approve` - Approve payout (Admin only)

---

### H. In-App Chat ✅

**WebSocket Connection:**

```
ws://<host>/ws/chat?job_id={job_id}
```

**Send Message:**

```json
{
  "type": "message",
  "content": "I'm arriving in 5 minutes",
  "message_type": "text|image",
  "media_id": "uuid-optional"
}
```

**Receive Message:**

```json
{
  "id": "uuid",
  "job_id": "uuid",
  "sender_id": "uuid",
  "sender_type": "driver|customer",
  "content": "Message text",
  "message_type": "text|image",
  "media_url": "https://storage.example.com/image.jpg",
  "created_at": "2026-03-01T10:00:00Z"
}
```

**Get Chat History:**

```http
GET /api/chat/job/:job_id/history
```

**Features:**

- Real-time WebSocket messaging
- Persistent chat history in PostgreSQL
- Support for text and image messages
- Chat created automatically for each job/food order

**UI Requirements:**

- Add chat button in trip screen
- Real-time messaging via WebSocket
- Show chat history on open
- Support text and image messages (camera/gallery)
- Auto-scroll to latest message
- Different styling for sender/receiver

---

### I. Media Service (Presigned URLs) ✅

**Request Upload URL:**

```http
POST /api/media/upload-url
```

**Request:**

```json
{
  "file_type": "image/jpeg",
  "file_size": 1024000,
  "purpose": "driver_document|chat_attachment|profile_picture"
}
```

**Response:**

```json
{
  "upload_url": "https://storage.example.com/bucket/key?X-Amz-Signature=...",
  "file_key": "uploads/drivers/uuid/timestamp.jpg",
  "media_id": "uuid",
  "expires_in": 3600
}
```

**Upload Flow:**

1. Call `/api/media/upload-url` to get presigned URL
2. Upload file directly via PUT request to `upload_url`
3. Use `file_key` or `media_id` in subsequent API calls

**Use Cases:**

- Driver document uploads
- Chat image attachments
- Profile pictures

**UI Requirements:**

- Compress images before upload (max 5MB recommended)
- Show upload progress
- Handle upload errors gracefully

---

## 8. ⚠️ Not Ready - Do Not Integrate

### SOS/Emergency System

**Status:** Backend code complete, but routes NOT wired in server.go

**Planned Endpoints:**

```http
POST /api/customer/sos
GET  /api/customer/sos/history
GET  /api/admin/sos/active
```

**Action:** Wait for next release before integrating

---

## 9. Integration Checklist

### Priority 1 (Critical for Production)

- [ ] **FCM Push Notifications** - Firebase SDK integration
- [ ] **Media Service** - Presigned upload flow
- [ ] **Document Verification** - Driver upload UI
- [ ] **Surge Pricing** - Update fare estimation UI
- [ ] **Cancellation Fee** - Show fee warnings

### Priority 2 (High Value)

- [ ] **Scheduled Rides** - Booking flow
- [ ] **Multi-Stop Rides** - Waypoint support
- [ ] **In-App Chat** - WebSocket messaging
- [ ] **Driver Earnings** - Payout dashboard
- [ ] **Driver Cancel** - Handle cancellation notifications

### Priority 3 (Nice to Have)

- [ ] **Demand Heatmap** - Driver app overlay
- [ ] **SOS Emergency** - Wait for next release

---

## 10. Testing Checklist

Before production release, test these flows:

1. **Customer booking with surge pricing active**
   - Verify `surge_multiplier` and `final_fare` display correctly
   - Show surge message to user

2. **Driver document upload and status check**
   - Upload all 4 required documents
   - Verify "Go Online" blocked until all approved
   - Test rejection and re-upload flow

3. **Job cancellation (customer and driver)**
   - Customer: First cancellation free, 2nd+ shows 20 THB fee
   - Driver: Must provide reason, customer receives FCM

4. **Payout request and history**
   - Request payout with bank account
   - Verify minimum amount validation (100 THB)
   - Check payout history with status

5. **Chat messaging during trip**
   - Connect to WebSocket
   - Send text and image messages
   - Verify chat history persistence

6. **Scheduled ride booking**
   - Book ride 7 days in advance
   - Verify automatic dispatch
   - Test free cancellation >1 hour before

---

## 11. API Documentation

- **Swagger UI:** `http://localhost:8080/swagger/index.html`
- **Admin Dashboard:** `http://localhost:8080/admin-dashboard`
- **Postman Collection:** Synced via GitHub Actions
