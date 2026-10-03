import '../../core/config/app_constants.dart';

/// App settings model (payment methods, VIP prices)
class AppSettingsModel {
  const AppSettingsModel({
    required this.gcashNumber,
    required this.mayaNumber,
    required this.qrUrl,
    required this.vipMonthlyPrice,
    required this.vipYearlyPrice,
  });

  final String gcashNumber;
  final String mayaNumber;
  final String qrUrl;
  final double vipMonthlyPrice;
  final double vipYearlyPrice;

  /// Creates an AppSettingsModel from Firestore document
  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      gcashNumber: map['gcashNumber'] as String? ?? '',
      mayaNumber: map['mayaNumber'] as String? ?? '',
      qrUrl: map['qrUrl'] as String? ?? '',
      vipMonthlyPrice:
          (map['vipMonthlyPrice'] as num?)?.toDouble() ??
          AppConstants.defaultVipMonthlyPrice,
      vipYearlyPrice:
          (map['vipYearlyPrice'] as num?)?.toDouble() ??
          AppConstants.defaultVipYearlyPrice,
    );
  }

  /// Converts AppSettingsModel to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'gcashNumber': gcashNumber,
      'mayaNumber': mayaNumber,
      'qrUrl': qrUrl,
      'vipMonthlyPrice': vipMonthlyPrice,
      'vipYearlyPrice': vipYearlyPrice,
    };
  }

  /// Creates a copy with updated fields
  AppSettingsModel copyWith({
    String? gcashNumber,
    String? mayaNumber,
    String? qrUrl,
    double? vipMonthlyPrice,
    double? vipYearlyPrice,
  }) {
    return AppSettingsModel(
      gcashNumber: gcashNumber ?? this.gcashNumber,
      mayaNumber: mayaNumber ?? this.mayaNumber,
      qrUrl: qrUrl ?? this.qrUrl,
      vipMonthlyPrice: vipMonthlyPrice ?? this.vipMonthlyPrice,
      vipYearlyPrice: vipYearlyPrice ?? this.vipYearlyPrice,
    );
  }

  @override
  String toString() {
    return 'AppSettingsModel(gcashNumber: $gcashNumber, mayaNumber: $mayaNumber)';
  }
}
