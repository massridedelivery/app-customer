# Customer App — Food Delivery API Binding Guide

A step-by-step integration guide for the **customer client** (mobile/web) binding to the food-delivery flow, using the APIs that exist in the backend today. It follows the real user journey:

**Discovery → Restaurant selection → Menu → Delivery address → Cart → Estimate → Checkout → Tracking.**

All paths, payloads, and behaviors below are taken from the wired code (`internal/server/server.go`, `internal/discovery`, `internal/restaurant`, `internal/menu`, `internal/foodorder`, `internal/customer`, `internal/promo`, `internal/ws`). Where a field is ambiguous, the Go structs in those packages are authoritative.

---

## 0. Connection model & conventions

Two channels:

| Channel | Use |
|---------|-----|
| **REST** (HTTPS/JSON) | Everything: browse, build order, checkout, track |
| **WebSocket** (WSS) | Live order-status push after checkout |

| Item | Value |
|------|-------|
| Dev base URL | `https://driver-api-dev.nutchaphut.dev` |
| WebSocket | `wss://driver-api-dev.nutchaphut.dev/ws?token=<access_token>` |
| Auth header | `Authorization: Bearer <access_token>` on every `/api/**` call |
| Content type | `application/json` |
| Customer role | All food-customer routes require role **`customer`** |
| Rate limits | 100 req/min/user globally; **placing an order is 10/min**; OTP 3/15min |

### Auth in one paragraph
Register/login to get a token pair (`{access_token, refresh_token, expires_in}`):
`POST /auth/register` (`role: "customer"`) or `POST /auth/login` (email/password), or phone OTP via `POST /auth/otp/send` → `POST /auth/otp/verify` (`role: "customer"`, dev OTP = `123456`). On `401`, call `POST /auth/refresh` once and retry. Full auth details are shared across roles; this guide focuses on the food journey.

---

## 1. Discovery flow

The home screen and search are served by the **discovery** service (`/api/discovery`, role `customer`). All take the user's current `lat`/`lng` so results are distance-aware.

### 1.1 Home feed
```
GET /api/discovery/home?lat=13.7401&lng=100.5601
```
Returns a `HomeResponse`:
```json
{
  "categories": [ { "id": "...", "name": "...", "name_th": "...", "slug": "..." } ],
  "sections":   [ { "id": "...", "title": "Near you", "type": "RESTAURANT_GRID", "items": [ /* restaurants or banners */ ] } ]
}
```
`400` if `lat`/`lng` are missing/invalid. Render `categories` as a chip row and `sections` as carousels/grids. Banners carry an `action_type` (`RESTAURANT | CATEGORY | CAMPAIGN | URL`) and `action_value` — bind taps accordingly.

### 1.2 Search
```
GET /api/discovery/search?q=somtam&lat=13.74&lng=100.56&limit=20&offset=0&category=thai&is_open=true&max_distance=5
```
- `q` (required, 1–100 chars), `lat`/`lng` (required).
- Optional: `limit`, `offset`, `category` (slug), `is_open` (bool), `max_distance` (km).
Returns `{ "items": [ ...restaurants ], "total": <int> }`. Use `total` for pagination.

### 1.3 Category browse
```
GET /api/discovery/categories                                   // list all active categories
GET /api/discovery/categories/:id?lat=..&lng=..&limit=..&offset=..   // restaurants in a category
```

### 1.4 Saved (favorites) & reorder
```
GET    /api/discovery/saved?lat=..&lng=..        // saved restaurants (distance-aware)
POST   /api/discovery/saved/:restaurantId        // favorite
DELETE /api/discovery/saved/:restaurantId        // unfavorite
GET    /api/discovery/reorder                    // quick "order again" from past orders
```

### 1.5 Nearby (map / "restaurants around me")
The food namespace also exposes a simpler nearby search (5 km radius, open restaurants):
```
GET /api/food/customer/restaurants/nearby?lat=13.74&lng=100.56
```
Returns `NearbyRestaurant[]` — a `Profile` plus delivery hints:
```json
{
  "user_id": "uuid",
  "restaurant_name": "Som Tam House",
  "lat": 13.7401, "lng": 100.5601,
  "rating": 4.6, "is_open": true, "min_order_amount": 100,
  "distance_km": 1.2,
  "delivery_fee": 32.0,
  "duration_min": 14,
  "is_estimate": true,
  "is_sponsored": false
}
```
`delivery_fee`/`duration_min` here are **preview estimates** for list display (`is_estimate: true`); the binding total comes from `/estimate` and the placed order.

---

## 2. Restaurant selection

Once the user taps a restaurant:

### 2.1 Restaurant detail
```
GET /api/food/customer/restaurants/:id
```
Returns the full `Profile` (`restaurant_name`, `address`, `lat/lng`, `rating`, `is_open`, `min_order_amount`, `cuisine_type`, images, `verification_status`). **Gate ordering on `is_open` and `is_active`** — a closed restaurant will reject checkout.

### 2.2 Menu
```
GET /api/food/customer/restaurants/:id/menu
# (equivalently) GET /api/food/restaurants/:id/menu   ← shared customer/restaurant
```
Returns `MenuResponse` grouped by category, with each item carrying its modifier groups:
```json
{
  "categories": [
    {
      "id": "cat-uuid", "name": "Main Dishes", "name_th": "...", "sort_order": 1, "is_active": true,
      "items": [
        {
          "id": "item-uuid",
          "category_id": "cat-uuid",
          "name": "Pad Thai", "name_th": "ผัดไทย",
          "price": 80.0,
          "image_url": "https://...",
          "is_available": true,
          "modifier_groups": [
            {
              "id": "grp-uuid", "name": "Spice Level",
              "min_select": 1, "max_select": 1, "is_active": true,
              "modifiers": [
                { "id": "mod-uuid", "name": "Mild",  "price": 0,  "is_available": true },
                { "id": "mod-uuid2","name": "Thai Hot","price": 0, "is_available": true }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```
Binding rules for the item-detail screen:
- Hide / disable items where `is_available == false`; same for individual modifiers.
- For each **active** modifier group, enforce `min_select`/`max_select` selection rules in the UI (the server re-validates at checkout).
- Display price = `item.price + Σ(selected modifier.price)`.

### 2.3 Reviews (optional, on restaurant page)
```
GET /api/food/restaurants/:id/reviews?limit=20&offset=0
→ { "reviews": [ { "rating": 5, "comment": "...", "is_anonymous": false, "item_reviews": [...] } ], "limit": 20, "offset": 0 }
```

---

## 3. Delivery address

Capture the drop-off as `delivery_lat` + `delivery_lng` (+ optional human-readable `delivery_address` and `delivery_notes`). Three sources:

### 3.1 Saved places (customer address book)
```
GET    /api/customer/places                 // → [{ id, name, lat, lng }]
POST   /api/customer/places                 // { "name": "Home", "lat": 13.74, "lng": 100.56 }
DELETE /api/customer/places/:id
```
The profile (`GET /api/customer/profile`) also embeds `saved_places`.

### 3.2 Pin-snap (precise map pin)
When the user drops/drags a map pin, snap it to a sensible road/POI coordinate before using it:
```
GET /api/customer/pin-snap?lat=13.7402&lng=100.5605
```
Use the snapped coordinates as `delivery_lat`/`delivery_lng`.

### 3.3 Manual entry
Free-text `delivery_address` + `delivery_notes` plus coordinates from the device GPS or geocoder.

> The backend runs a **service-coverage check** on the delivery coordinates at checkout. If the area isn't served you get `422` (see §6) — validate early by attempting `/estimate`, which fails the same way if uncovered is reached at order time. Always send real coordinates.

---

## 4. Cart (client-side)

**There is no server-side cart.** The cart is held in the client and serialized into the order's `items` array at checkout. Each line item:

```json
{
  "menu_item_id": "item-uuid",
  "quantity": 2,
  "variant_options": "optional free-form string",
  "modifier_ids": ["mod-uuid", "mod-uuid2"]
}
```

Client responsibilities while the cart is open:
- Keep all items from a **single restaurant** (one `restaurant_id` per order).
- Track `modifier_ids` per line from the user's modifier selections.
- Compute a display subtotal locally, but treat the server's returned totals as authoritative (prices are re-fetched from the DB at checkout; client prices are never trusted).
- Optionally warn if the running food subtotal is below the restaurant's `min_order_amount` — checkout will reject with `400` otherwise.

---

## 5. Checkout

Checkout is a 2–3 call sequence: **(optional promo check) → estimate → place order**.

### 5.1 Fare estimate & tier selection
```
POST /api/food/customer/estimate
```
```json
{
  "restaurant_id": "rest-uuid",
  "items": [ { "menu_item_id": "item-uuid", "quantity": 2 } ],
  "delivery_lat": 13.75,
  "delivery_lng": 100.56
}
```
Returns the available **delivery tiers** so the user can pick speed vs. price:
```json
{
  "base_fee": 32.0,
  "distance_km": 1.2,
  "food_total": 160.0,
  "tiers": [
    { "tier": "SAVER",    "display_name": "ประหยัด / Saver",  "delivery_fee": 22, "estimated_min": 35, "description": "Cheaper, may batch" },
    { "tier": "STANDARD", "display_name": "ปกติ / Standard",  "delivery_fee": 32, "estimated_min": 25, "description": "Normal" },
    { "tier": "PRIORITY", "display_name": "ด่วน / Priority",  "delivery_fee": 48, "estimated_min": 18, "description": "Fastest, no batching" }
  ]
}
```
Tier semantics (drives the final fee multiplier on the order):

| Tier | Fee | Behavior |
|------|-----|----------|
| `SAVER` | 0.7× base | Cheapest; order may be batched with others → slower |
| `STANDARD` | 1.0× base | Default; opportunistic batching |
| `PRIORITY` | 1.5× base | Direct routing, no batching, fastest |

> Note: `estimate.food_total` sums **base item prices only** (it does not add modifier prices). The authoritative food total and grand total are computed when you place the order, so re-read them from the order response for the final confirmation screen.

### 5.2 (Optional) Promo validation
```
GET /api/customer/promo/validate?code=WELCOME50&fare=192        // preview discount for a fare
GET /api/customer/promo/list                                     // active promos to show the user
```
You don't have to pre-validate — promo codes can be passed straight into the order; invalid codes are simply ignored (the order still succeeds, no discount). Pre-validating only improves UX.

### 5.3 Place the order (checkout)
```
POST /api/food/customer/orders        (rate-limited: 10/min)
```
Full `CreateOrderRequest`:
```json
{
  "restaurant_id": "rest-uuid",
  "items": [
    { "menu_item_id": "item-uuid", "quantity": 2, "modifier_ids": ["mod-uuid"], "variant_options": null }
  ],
  "delivery_lat": 13.75,
  "delivery_lng": 100.56,
  "delivery_address": "123 Sukhumvit Rd, Bangkok",
  "delivery_notes": "Ring the bell, 4th floor",
  "payment_method": "CASH",
  "tier": "STANDARD",
  "promo_codes": ["WELCOME50"],
  "idempotency_key": "client-generated-uuid"
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `restaurant_id` | ✅ | Single restaurant per order |
| `items` | ✅ (min 1) | See §4; `modifier_ids` validated against the item's groups |
| `delivery_lat` / `delivery_lng` | ✅ | Used for coverage check, fee, and dispatch |
| `delivery_address` | optional | Human-readable label |
| `delivery_notes` | optional | Courier instructions |
| `payment_method` | optional | Defaults to `CASH`. Also `CORPORATE`. **(See payment note below.)** |
| `tier` | optional | `SAVER` \| `STANDARD` \| `PRIORITY`; defaults to `STANDARD` |
| `promo_codes` | optional | Array; invalid ones ignored |
| `idempotency_key` | optional but **recommended** | See §5.4 |

**Success** → `201 Created` with the full `Order`:
```json
{
  "id": "order-uuid",
  "status": "PLACED",
  "restaurant_id": "rest-uuid",
  "food_total": 170.0,
  "delivery_fee": 32.0,
  "promo_discount": 50.0,
  "total_amount": 152.0,
  "payment_method": "CASH",
  "tier": "STANDARD",
  "delivery_lat": 13.75, "delivery_lng": 100.56,
  "delivery_address": "123 Sukhumvit Rd",
  "items": [ { "id": "orderItem-uuid", "menu_item_id": "...", "name": "Pad Thai", "quantity": 2, "unit_price": 80, "selected_modifiers": [...], "subtotal": 170 } ],
  "placed_at": "2026-05-26T10:00:00Z"
}
```
Show `total_amount` as the confirmed price. Keep `order.id` for tracking.

> **Payment (phase 1 = postpaid):** there is **no payment step at checkout**. The customer is not charged up-front — payment is settled at delivery. Use `CASH` (default) or `CORPORATE`. Card/PromptPay pre-auth is not part of the current flow, so the client does **not** need to create a payment intent before placing a food order.

### 5.4 Idempotency (avoid double orders)
Generate a fresh UUID per checkout attempt and send it as `idempotency_key`. If the request is retried (network blip, double-tap) with the **same** key, the server returns the **existing** order instead of creating a duplicate (valid for 24h). Generate a new key only when the user starts a genuinely new checkout.

---

## 6. Order confirmation & live tracking

After `201`, open/keep the WebSocket and also support polling as a fallback.

### 6.1 Read order state
```
GET /api/food/customer/orders/:id      // single order (full detail)
GET /api/food/customer/orders          // customer's order list (history + active)
GET /api/customer/history?type=FOOD    // unified ride+food history (paginated)
```

### 6.2 WebSocket events the customer receives
Connect `wss://…/ws?token=<access_token>`. Each message is JSON with a `type`:

| `type` | Meaning |
|--------|---------|
| `new_food_order` | Echo right after you place the order (`order` payload) |
| `order_accepted` | Restaurant accepted; now preparing |
| `order_rejected` | Restaurant rejected (terminal) |
| `order_preparing` | Kitchen started |
| `order_ready` | Ready for pickup |
| `driver_assigned` | A driver took the delivery (`order_id`, `driver_id`) |
| `order_picked_up` | Driver picked up the food |
| `order_delivered` | Delivered (terminal) |
| `delivery_failed` | Failed delivery after customer no-show (terminal) |
| `customer_no_show_warning` | Driver reports you're not reachable — prompt the user to respond |
| `ITEMS_OOS` / `ORDER_CANCELLED_OOS` | Item(s) out of stock; total adjusted, or order cancelled |
| `PREP_TIME_UPDATED` | Restaurant extended prep time |
| `externally_dispatched` | Order handed to an external courier |
| `chat_message` | New chat message from the driver (see §6.4) |

Status-event envelope:
```json
{ "type": "order_ready", "order_id": "uuid", "status": "READY_FOR_PICKUP", "order": { /* order snapshot */ } }
```
Push notifications (FCM) are also sent for accepted/ready/picked-up/delivered as a fallback when the socket is closed — register via `POST /api/notifications/register-device`.

### 6.3 Status machine (customer view)
```
PLACED → RESTAURANT_ACCEPTED → PREPARING → READY_FOR_PICKUP → DRIVER_ASSIGNED → DRIVER_PICKED_UP → DELIVERED
   │
   ├─ RESTAURANT_REJECTED (terminal)
   ├─ CANCELLED (terminal — customer cancelled while PLACED)
   └─ FAILED_DELIVERY (terminal)
```

### 6.4 Chat with the driver
```
GET  /api/food/customer/orders/:id/chat?limit=50      // history (paginated; ?before=<RFC3339> cursor)
POST /api/food/customer/orders/:id/chat               // { "msg_type": "text", "text": "I'm at the lobby" }
```
Live inbound messages arrive over the WebSocket as `chat_message`. The chat room is created lazily, so fetching history before any message returns an empty list.

### 6.5 Cancel
```
POST /api/food/customer/orders/:id/cancel
```
Allowed **only while the order is `PLACED`** (before the restaurant accepts). After acceptance the endpoint returns `400 cannot cancel order after restaurant has accepted`.

### 6.6 Review (after delivery)
```
POST /api/food/customer/orders/:id/review
{ "rating": 5, "comment": "Great!", "is_anonymous": false, "item_reviews": [ { "order_item_id": "...", "rating": 5, "comment": "" } ] }
```
Only valid once the order is `DELIVERED`; one review per order.

> **Live driver GPS — current limitation.** The platform streams a `driver_location` WS event to *ride* customers, but for **food orders this live-location stream is not wired** (the driver↔food-customer binding is stored in Redis but not consumed by the location handler). Today, track food progress via the **status events** in §6.2 and by polling `GET /orders/:id`. If you need a live courier dot on the map for food, that needs a backend change — flag it to the backend team.

---

## 7. Error handling

Bodies are `{"message": "..."}` (food handlers) or `{"error": "..."}` (some shared handlers).

| Status | Cause | Client action |
|--------|-------|---------------|
| `400` | Below `min_order_amount`, restaurant not open, item not available, invalid transition (cancel too late) | Show a specific message; re-fetch menu/order |
| `401` | Missing/expired token | Refresh once, retry; else re-login |
| `403` | Accessing an order that isn't yours | — |
| `404` | Unknown restaurant/order | — |
| `422` | Delivery area not covered | Ask the user to pick a different address |
| `429` | Rate limit (10/min for placing orders) | Back off; debounce the checkout button |
| `500` | Server error | Retry with the same `idempotency_key` |

---

## 8. End-to-end binding checklist

1. **Auth** as `role: customer`; store the token pair; attach Bearer on every call.
2. **Discovery**: `GET /api/discovery/home` (and `/search`, `/categories`, `/saved`, `/reorder`) using device `lat`/`lng`.
3. **Select restaurant**: `GET /api/food/customer/restaurants/:id` → gate on `is_open`.
4. **Load menu**: `GET .../restaurants/:id/menu`; render items + modifier groups (`min/max_select`).
5. **Pick delivery address**: from `GET /api/customer/places`, a `pin-snap`ped pin, or manual entry → `delivery_lat/lng` (+ address/notes).
6. **Build the cart** client-side as `items[]` with `modifier_ids`.
7. **Estimate**: `POST /api/food/customer/estimate` → let the user choose a `tier`.
8. *(optional)* **Promo**: `GET /api/customer/promo/validate`.
9. **Checkout**: `POST /api/food/customer/orders` with a fresh `idempotency_key` → store `order.id`, show `total_amount` (postpaid, no payment step).
10. **Track**: open `wss://…/ws?token=…`, handle the status events; poll `GET /orders/:id` as fallback.
11. **Post-delivery**: chat (§6.4), cancel-while-PLACED (§6.5), review after `DELIVERED` (§6.6).

---

*Source of truth: `internal/server/server.go` (routes), `internal/discovery` (home/search/categories/saved), `internal/restaurant` & `internal/menu` (selection + menu), `internal/customer` (profile/saved places), `internal/foodorder` (estimate/checkout/tracking), `internal/promo` (promos), `internal/ws` (WebSocket).*
