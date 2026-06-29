import '../../domain/entities/tracker_info.dart';

/// Tracker info model for RTDB serialization
class TrackerInfoModel extends TrackerInfoEntity {
  const TrackerInfoModel({
    required super.imei,
    super.model,
    super.provider,
    super.ownerId,
    super.linkedAt,
  });

  /// Create a TrackerInfoModel from RTDB data
  factory TrackerInfoModel.fromRtdb(Map<dynamic, dynamic> data, String imei) {
    return TrackerInfoModel(
      imei: imei,
      model: data['model'] as String?,
      provider: data['provider'] as String?,
      ownerId: data['ownerId'] as String?,
      linkedAt: data['linkedAt'] != null
          ? DateTime.parse(data['linkedAt'] as String)
          : null,
    );
  }

  /// Convert to RTDB JSON
  Map<String, dynamic> toRtdb() {
    return {
      'imei': imei,
      'model': model,
      'provider': provider,
      'ownerId': ownerId,
      'linkedAt': linkedAt?.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  @override
  TrackerInfoModel copyWith({
    String? imei,
    String? model,
    String? provider,
    String? ownerId,
    DateTime? linkedAt,
  }) {
    return TrackerInfoModel(
      imei: imei ?? this.imei,
      model: model ?? this.model,
      provider: provider ?? this.provider,
      ownerId: ownerId ?? this.ownerId,
      linkedAt: linkedAt ?? this.linkedAt,
    );
  }
}

/// Tracker live model for RTDB serialization
class TrackerLiveModel extends TrackerLiveEntity {
  const TrackerLiveModel({
    required super.imei,
    required super.battery,
    required super.lat,
    required super.lng,
    required super.speed,
    required super.online,
    required super.datetime,
    required super.ts,
  });

  /// Create a TrackerLiveModel from RTDB data
  factory TrackerLiveModel.fromRtdb(Map<dynamic, dynamic> data, String imei) {
    return TrackerLiveModel(
      imei: imei,
      battery: (data['battery'] as num?)?.toInt() ?? 0,
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
      online: data['online'] as bool? ?? false,
      datetime: data['datetime'] != null
          ? DateTime.parse(data['datetime'] as String)
          : DateTime.now(),
      ts: (data['ts'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convert to RTDB JSON
  Map<String, dynamic> toRtdb() {
    return {
      'imei': imei,
      'battery': battery,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'online': online,
      'datetime': datetime.toIso8601String(),
      'ts': ts,
    };
  }
}

/// Tracker status model for RTDB serialization
class TrackerStatusModel extends TrackerStatusEntity {
  const TrackerStatusModel({
    required super.imei,
    required super.battery,
    required super.online,
    required super.speed,
    required super.lastUpdate,
  });

  /// Create a TrackerStatusModel from RTDB data
  factory TrackerStatusModel.fromRtdb(Map<dynamic, dynamic> data, String imei) {
    return TrackerStatusModel(
      imei: imei,
      battery: (data['battery'] as num?)?.toInt() ?? 0,
      online: data['online'] as bool? ?? false,
      speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
      lastUpdate: data['lastUpdate'] != null
          ? DateTime.parse(data['lastUpdate'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to RTDB JSON
  Map<String, dynamic> toRtdb() {
    return {
      'battery': battery,
      'online': online,
      'speed': speed,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
}
