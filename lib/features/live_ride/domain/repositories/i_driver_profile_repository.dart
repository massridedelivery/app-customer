import 'package:customer_app/features/live_ride/domain/models/customer_jobs_active_model.dart';

abstract interface class IDriverProfileRepository {
  Future<CustomerJobsActiveModel> getDriverProfile();
}
