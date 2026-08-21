// Verifies the FE models parse the newly-merged backend fields
// (SCRUM-54/64/65/66 and v1.6.1-dev11: SCRUM-71/76/69) from real BE JSON.
import 'package:customer_app/features/live_ride/domain/models/customer_jobs_active_model.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_estimate.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:customer_app/features/ride_booking/domain/models/fare_estimation_response.dart';
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SCRUM-64 · drivers_nearby', () {
    test('parses drivers_nearby per vehicle type', () {
      final v = VehicleEstimation.fromJson(const {
        'vehicle_type_id': 'v1',
        'vehicle_type_name': 'economy',
        'display_name': 'Economy Car',
        'base_fare': 100.0,
        'discount': 0.0,
        'total_fare': 123.0,
        'surged_fare': 123.0,
        'available': true,
        'drivers_nearby': 4,
      });
      expect(v.driversNearby, 4);
    });

    test('drivers_nearby absent → null (gated, no crash)', () {
      final v = VehicleEstimation.fromJson(const {
        'vehicle_type_id': 'v1',
        'vehicle_type_name': 'economy',
        'display_name': 'Economy Car',
        'base_fare': 100.0,
        'discount': 0.0,
        'total_fare': 123.0,
        'surged_fare': 123.0,
      });
      expect(v.driversNearby, isNull);
    });

    test('drivers_nearby 0 preserved (distinct from null)', () {
      final v = VehicleEstimation.fromJson(const {
        'vehicle_type_id': 'v1',
        'vehicle_type_name': 'economy',
        'display_name': 'Economy Car',
        'base_fare': 100.0,
        'discount': 0.0,
        'total_fare': 123.0,
        'surged_fare': 123.0,
        'drivers_nearby': 0,
      });
      expect(v.driversNearby, 0);
    });
  });

  group('SCRUM-66 · estimate polyline + distance/duration', () {
    test('EstimateJobResponse parses estimations[], distance/duration, polyline',
        () {
      final r = FareEstimationResponse.fromJson(const {
        'distance_km': 5.9,
        'duration_min': 8,
        'polyline': 'abc123',
        'encoded_polyline': '',
        'overview_polyline': '',
        'estimations': [
          {
            'vehicle_type_id': 'v1',
            'vehicle_type_name': 'economy',
            'display_name': 'Economy Car',
            'base_fare': 100.0,
            'discount': 0.0,
            'total_fare': 123.0,
            'surged_fare': 123.0,
            'drivers_nearby': 3,
          }
        ],
      });
      expect(r.distanceKm, 5.9);
      expect(r.durationMin, 8);
      // Encoded route polyline is read into `waypoint` from
      // polyline/encoded_polyline/overview_polyline.
      expect(r.waypoint, 'abc123');
      expect(r.estimations.single.driversNearby, 3);
    });
  });

  group('SCRUM-65 · active job cancel fees', () {
    test('parses estimated_cancel_fee + cancellation_fee + polyline', () {
      final j = CustomerJobsActiveModel.fromJson(const {
        'id': 'job1',
        'status': 'ACCEPTED',
        'fare': 120.0,
        'distance_km': 5.9,
        'polyline': 'poly-xyz',
        'estimated_cancel_fee': 20.0,
        'cancellation_fee': 0.0,
      });
      expect(j.estimatedCancelFee, 20.0);
      expect(j.cancellationFee, 0.0);
      expect(j.polyline, 'poly-xyz');
    });

    test('fees absent → default 0 (no crash)', () {
      final j = CustomerJobsActiveModel.fromJson(const {
        'id': 'job1',
        'status': 'PENDING',
      });
      expect(j.estimatedCancelFee, 0.0);
      expect(j.cancellationFee, 0.0);
    });
  });

  group('SCRUM-81 · nearby driver positions on estimate', () {
    test('parses nearby_drivers[] with optional vehicle_type_id', () {
      final r = FareEstimationResponse.fromJson(const {
        'distance_km': 4.2,
        'duration_min': 12,
        'estimations': [],
        'nearby_drivers': [
          {'lat': 13.751, 'lng': 100.502, 'vehicle_type_id': 'eco'},
          {'lat': 13.749, 'lng': 100.498},
        ],
      });
      expect(r.nearbyDrivers.length, 2);
      expect(r.nearbyDrivers.first.lat, 13.751);
      expect(r.nearbyDrivers.first.vehicleTypeId, 'eco');
      expect(r.nearbyDrivers[1].vehicleTypeId, isNull);
    });

    test('nearby_drivers absent → empty (gated, no crash)', () {
      final r = FareEstimationResponse.fromJson(const {
        'distance_km': 4.2,
        'duration_min': 12,
        'estimations': [],
      });
      expect(r.nearbyDrivers, isEmpty);
    });
  });

  group('SCRUM-71 · messenger delivery modes (v1.6.1-dev11)', () {
    test('estimate parses service_levels[] + delivery_type', () {
      final e = MessengerEstimate.fromJson(const {
        'distance_km': 4,
        'duration_min': 10,
        'base_fare': 49,
        'surcharge': 0,
        'discount': 0,
        'total_fare': 49,
        'delivery_type': 'INSTANT',
        'service_levels': [
          {
            'delivery_type': 'INSTANT',
            'label': 'ส่งด่วน',
            'base_fare': 49,
            'size_surcharge': 0,
            'express_surcharge': 0,
            'discount': 0,
            'total_fare': 49,
            'pickup_eta_min': 15,
            'deliver_by': '2026-08-21T09:25:00Z',
          },
          {
            'delivery_type': 'TWO_HOUR',
            'label': 'ภายใน 2 ชั่วโมง',
            'base_fare': 49,
            'total_fare': 49,
            'pickup_eta_min': 60,
            'deliver_by': '2026-08-21T11:00:00Z',
          },
        ],
      });
      expect(e.deliveryType, 'INSTANT');
      expect(e.serviceLevels.length, 2);
      expect(e.serviceLevels.first.label, 'ส่งด่วน');
      expect(e.serviceLevels.first.pickupEtaMin, 15);
      expect(e.serviceLevels.first.deliverBy, '2026-08-21T09:25:00Z');
      expect(e.serviceLevels[1].deliveryType, 'TWO_HOUR');
      expect(e.serviceLevels[1].totalFare, 49);
    });

    test('estimate with no service_levels → empty (gated, no crash)', () {
      final e = MessengerEstimate.fromJson(const {'total_fare': 49});
      expect(e.serviceLevels, isEmpty);
      expect(e.deliveryType, isNull);
    });

    test('order parses delivery_type/express_surcharge; legacy defaults', () {
      final o = MessengerOrder.fromJson(const {
        'id': 'm1',
        'delivery_type': 'TWO_HOUR',
        'express_surcharge': 0,
        'pickup_eta_min': 60,
        'deliver_by': '2026-08-21T11:30:00Z',
      });
      expect(o.deliveryType, 'TWO_HOUR');
      expect(o.pickupEtaMin, 60);
      expect(o.deliverBy, '2026-08-21T11:30:00Z');
      // Legacy order without the keys → INSTANT / 0 / null.
      final legacy = MessengerOrder.fromJson(const {'id': 'm0'});
      expect(legacy.deliveryType, 'INSTANT');
      expect(legacy.expressSurcharge, 0.0);
      expect(legacy.pickupEtaMin, isNull);
    });
  });

  group('SCRUM-69 · messenger customer_rating + comment', () {
    test('parses rating + comment; comment absent → null', () {
      final o = MessengerOrder.fromJson(const {
        'id': 'm1',
        'customer_rating': 5,
        'customer_comment': 'ส่งไวมาก',
      });
      expect(o.customerRating, 5);
      expect(o.isReviewed, true);
      expect(o.customerComment, 'ส่งไวมาก');

      final noReview = MessengerOrder.fromJson(const {'id': 'm2'});
      expect(noReview.customerRating, 0);
      expect(noReview.isReviewed, false);
      expect(noReview.customerComment, isNull);
    });
  });

  group('SCRUM-76 · active-job ETA resync', () {
    test('parses eta_min/arrive_at/distance_remaining_m', () {
      final j = CustomerJobsActiveModel.fromJson(const {
        'id': 'job1',
        'status': 'ACCEPTED',
        'eta_min': 8,
        'arrive_at': '2026-08-21T09:38:00Z',
        'distance_remaining_m': 3200,
      });
      expect(j.etaMin, 8);
      expect(j.arriveAt, '2026-08-21T09:38:00Z');
      expect(j.distanceRemainingM, 3200);
    });

    test('ETA keys absent → null (unknown, not 0)', () {
      final j = CustomerJobsActiveModel.fromJson(const {
        'id': 'job1',
        'status': 'PENDING',
      });
      expect(j.etaMin, isNull);
      expect(j.arriveAt, isNull);
      expect(j.distanceRemainingM, isNull);
    });
  });
}
