// Verifies the FE models parse the newly-merged backend fields
// (SCRUM-54/64/65/66) from Swagger-shaped JSON.
import 'package:customer_app/features/live_ride/domain/models/customer_jobs_active_model.dart';
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
}
