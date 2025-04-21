import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/datasources/local_datasource/end_trip_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/datasources/remote_datasource/end_trip_otp_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/entity/end_trip_otp_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/repo/end_trip_otp_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
class EndTripOtpRepoImpl implements EndTripOtpRepo {
  const EndTripOtpRepoImpl(this._remoteDataSource, this._localDataSource);

  final EndTripOtpRemoteDataSource _remoteDataSource;
  final EndTripOtpLocalDatasource _localDataSource;

  @override
  ResultFuture<String> getEndGeneratedOtp() async {
    try {
      debugPrint('🔄 Fetching end trip OTP from remote');
      final remoteOtp = await _remoteDataSource.getEndGeneratedOtp();
      return Right(remoteOtp);
    } on ServerException catch (e) {
      debugPrint('❌ Remote fetch failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

@override
ResultFuture<EndTripOtpEntity> loadEndTripOtpByTripId(String tripId) async {
  try {
    debugPrint('🔄 Loading OTP data for trip: $tripId');
    final remoteOtp = await _remoteDataSource.loadEndTripOtpByTripId(tripId);
    return Right(remoteOtp);
  } on ServerException catch (e) {
    debugPrint('❌ Failed to load OTP: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

@override
ResultFuture<EndTripOtpEntity> loadEndTripOtpById(String otpId) async {
  try {
    debugPrint('🔄 Loading OTP by ID: $otpId');
    final remoteOtp = await _remoteDataSource.loadEndTripOtpById(otpId);
    return Right(remoteOtp);
  } on ServerException catch (e) {
    debugPrint('❌ Failed to load OTP: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}


  @override
  ResultFuture<bool> verifyEndTripOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
  }) async {
    try {
      debugPrint('🔐 Verifying end trip OTP');
      final remoteResult = await _remoteDataSource.verifyEndTripOtp(
        enteredOtp: enteredOtp,
        generatedOtp: generatedOtp,
        tripId: tripId,
        otpId: otpId,
        odometerReading: odometerReading,
      );

      if (remoteResult) {
        await _localDataSource.verifyEndTripOtp(
          enteredOtp: enteredOtp,
          generatedOtp: generatedOtp,
          tripId: tripId,
          otpId: otpId,
          odometerReading: odometerReading,
        );
      }

      return Right(remoteResult);
    } on ServerException catch (e) {
      debugPrint('❌ Remote verification failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      debugPrint('❌ Local cache update failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
