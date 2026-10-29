import 'package:customer_app/features/live_ride/domain/models/customer_jobs_active_model.dart';

abstract interface class IDriverProfileRepository {
  Future<CustomerJobsActiveModel> getDriverProfile();

  /// One ride's status (`GET /api/customer/jobs/:id`), upper-cased; null when
  /// the customer has no such ride.
  Future<String?> getJobStatus(String jobId);
}
