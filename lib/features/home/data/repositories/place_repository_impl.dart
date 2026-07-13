import 'package:customer_app/core/error/server_exception.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/models/place_prediction.dart';
import 'package:customer_app/features/home/domain/repositories/place_repository.dart';
import 'package:customer_app/features/home/data/datasources/place_data_source.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_repository_impl.g.dart';

@riverpod
PlaceRepositoryImpl placeRepository(Ref ref) {
  final dataSource = ref.watch(placeDataSourceProvider);
  return PlaceRepositoryImpl(dataSource);
}

class PlaceRepositoryImpl implements PlaceRepository {
  final PlaceDataSource _dataSource;

  PlaceRepositoryImpl(this._dataSource);

  @override
  Future<List<PlacePrediction>> autocomplete(
    String query, {
    double? lat,
    double? lng,
  }) async {
    try {
      return await _dataSource.autocomplete(query, lat: lat, lng: lng);
    } on DioException catch (e) {
      throw ServerException(_message(e, 'ค้นหาสถานที่ไม่สำเร็จ'));
    }
  }

  @override
  Future<Place> getPlaceDetails(String placeId) async {
    try {
      return await _dataSource.getPlaceDetails(placeId);
    } on DioException catch (e) {
      throw ServerException(_message(e, 'ดึงข้อมูลสถานที่ไม่สำเร็จ'));
    }
  }

  @override
  Future<List<Place>> getRecentPlaces() async {
    try {
      final response = await _dataSource.getRecentPlaces();
      return response
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_message(e, 'โหลดสถานที่ล่าสุดไม่สำเร็จ'));
    }
  }

  @override
  Future<List<Place>> getSavedPlaces() async {
    try {
      final response = await _dataSource.getSavedPlaces();
      return response
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_message(e, 'โหลดสถานที่ที่บันทึกไม่สำเร็จ'));
    }
  }

  @override
  Future<void> addSavedPlace({
    required String name,
    required double lat,
    required double lng,
    String? address,
    bool? isDefault,
    String? id,
    String? note,
    String? phoneNumber,
  }) async {
    try {
      await _dataSource.addSavedPlace(
        name: name,
        lat: lat,
        lng: lng,
        address: address,
        isDefault: isDefault,
        id: id,
        note: note,
        phoneNumber: phoneNumber,
      );
    } on DioException catch (e) {
      throw ServerException(_message(e, 'บันทึกสถานที่ไม่สำเร็จ'));
    }
  }

  @override
  Future<Place> setDefaultPlace(String id) async {
    try {
      final response = await _dataSource.setDefaultPlace(id);
      return Place.fromJson(response);
    } on DioException catch (e) {
      throw ServerException(_message(e, 'ตั้งค่าสถานที่เริ่มต้นไม่สำเร็จ'));
    }
  }

  @override
  Future<Place?> getDefaultPlace() async {
    try {
      final response = await _dataSource.getDefaultPlace();
      return Place.fromJson(response);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 400) {
        return null;
      }
      throw ServerException(_message(e, 'ดึงสถานที่เริ่มต้นไม่สำเร็จ'));
    }
  }

  String _message(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }
}
