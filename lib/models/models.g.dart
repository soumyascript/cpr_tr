//cpr_training_app/lib/models/models.g.dart

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemConfig _$SystemConfigFromJson(Map<String, dynamic> json) => SystemConfig(
      compressionDirection: $enumDecodeNullable(
              _$CompressionDirectionEnumMap, json['compressionDirection']) ??
          CompressionDirection.increasing,
      maxCompressionRate:
          (json['maxCompressionRate'] as num?)?.toDouble() ?? 120.0,
      minCompressionRate:
          (json['minCompressionRate'] as num?)?.toDouble() ?? 100.0,
      movingWindow: json['movingWindow'] as int? ?? 5,
      hysteresis: (json['hysteresis'] as num?)?.toDouble() ?? 10.0,
      quietudePercent: (json['quietudePercent'] as num?)?.toDouble() ?? 0.1,
      maxQuietudeTime: (json['maxQuietudeTime'] as num?)?.toDouble() ?? 2.0,
      phaseDeterminationCycles: json['phaseDeterminationCycles'] as int? ?? 3,
      compressionOk: (json['compressionOk'] as num?)?.toDouble() ?? 200.0,
      compressionHi: (json['compressionHi'] as num?)?.toDouble() ?? 800.0,
      recoilOk: (json['recoilOk'] as num?)?.toDouble() ?? 100.0,
      recoilLow: (json['recoilLow'] as num?)?.toDouble() ?? 50.0,
      compressionRateSmoothingFactor:
          (json['compressionRateSmoothingFactor'] as num?)?.toDouble() ?? 0.3,
      compressionRateCalculationPeaks:
          json['compressionRateCalculationPeaks'] as int? ?? 5,
    );

Map<String, dynamic> _$SystemConfigToJson(SystemConfig instance) =>
    <String, dynamic>{
      'compressionDirection':
          _$CompressionDirectionEnumMap[instance.compressionDirection]!,
      'maxCompressionRate': instance.maxCompressionRate,
      'minCompressionRate': instance.minCompressionRate,
      'movingWindow': instance.movingWindow,
      'hysteresis': instance.hysteresis,
      'quietudePercent': instance.quietudePercent,
      'maxQuietudeTime': instance.maxQuietudeTime,
      'phaseDeterminationCycles': instance.phaseDeterminationCycles,
      'compressionOk': instance.compressionOk,
      'compressionHi': instance.compressionHi,
      'recoilOk': instance.recoilOk,
      'recoilLow': instance.recoilLow,
      'compressionRateSmoothingFactor': instance.compressionRateSmoothingFactor,
      'compressionRateCalculationPeaks':
          instance.compressionRateCalculationPeaks,
    };

const _$CompressionDirectionEnumMap = {
  CompressionDirection.increasing: 'increasing',
  CompressionDirection.decreasing: 'decreasing',
};

CloudConfig _$CloudConfigFromJson(Map<String, dynamic> json) => CloudConfig(
      provider: json['provider'] as String? ?? 'AWS S3',
      accessKeyId: json['accessKeyId'] as String? ?? '',
      secretKey: json['secretKey'] as String? ?? '',
      region: json['region'] as String? ?? '',
      bucketName: json['bucketName'] as String? ?? '',
      folderPrefix: json['folderPrefix'] as String?,
      minTimeElapsed: json['minTimeElapsed'] as int? ?? 5,
      aiDebriefing: json['aiDebriefing'] as bool? ?? false,
      aiDebriefingParameters: (json['aiDebriefingParameters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CloudConfigToJson(CloudConfig instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'accessKeyId': instance.accessKeyId,
      'secretKey': instance.secretKey,
      'region': instance.region,
      'bucketName': instance.bucketName,
      'folderPrefix': instance.folderPrefix,
      'minTimeElapsed': instance.minTimeElapsed,
      'aiDebriefing': instance.aiDebriefing,
      'aiDebriefingParameters': instance.aiDebriefingParameters,
    };

CPRSession _$CPRSessionFromJson(Map<String, dynamic> json) => CPRSession(
      id: json['id'] as int,
      sessionNumber: json['sessionNumber'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      durationMs: json['durationMs'] as int?,
      synced: json['synced'] as bool? ?? false,
      notes: json['notes'] as String?,
      appVersion: json['appVersion'] as String? ?? '1.0.0',
    );

Map<String, dynamic> _$CPRSessionToJson(CPRSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionNumber': instance.sessionNumber,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'durationMs': instance.durationMs,
      'synced': instance.synced,
      'notes': instance.notes,
      'appVersion': instance.appVersion,
    };

SensorSample _$SensorSampleFromJson(Map<String, dynamic> json) => SensorSample(
      id: json['id'] as int,
      sessionId: json['sessionId'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sensor1Raw: json['sensor1Raw'] as int,
      sensor2Raw: json['sensor2Raw'] as int,
      sensor1Avg: (json['sensor1Avg'] as num).toDouble(),
      sensor2Avg: (json['sensor2Avg'] as num).toDouble(),
    );

Map<String, dynamic> _$SensorSampleToJson(SensorSample instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'timestamp': instance.timestamp.toIso8601String(),
      'sensor1Raw': instance.sensor1Raw,
      'sensor2Raw': instance.sensor2Raw,
      'sensor1Avg': instance.sensor1Avg,
      'sensor2Avg': instance.sensor2Avg,
    };

CPREvent _$CPREventFromJson(Map<String, dynamic> json) => CPREvent(
      id: json['id'] as int,
      sessionId: json['sessionId'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
      payload: json['payload'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$CPREventToJson(CPREvent instance) => <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': instance.type,
      'payload': instance.payload,
    };

DebriefData _$DebriefDataFromJson(Map<String, dynamic> json) => DebriefData(
      sessionId: json['sessionId'] as int,
      durationSeconds: json['durationSeconds'] as int,
      cycleCount: json['cycleCount'] as int,
      averageRate: (json['averageRate'] as num).toDouble(),
      averageCCF: (json['averageCCF'] as num).toDouble(),
      totalCompressions: json['totalCompressions'] as int,
      goodCompressions: json['goodCompressions'] as int,
      totalRecoils: json['totalRecoils'] as int,
      goodRecoils: json['goodRecoils'] as int,
      breathsPerCycle: (json['breathsPerCycle'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      idealComparison: json['idealComparison'] as Map<String, dynamic>,
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$DebriefDataToJson(DebriefData instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'durationSeconds': instance.durationSeconds,
      'cycleCount': instance.cycleCount,
      'averageRate': instance.averageRate,
      'averageCCF': instance.averageCCF,
      'totalCompressions': instance.totalCompressions,
      'goodCompressions': instance.goodCompressions,
      'totalRecoils': instance.totalRecoils,
      'goodRecoils': instance.goodRecoils,
      'breathsPerCycle': instance.breathsPerCycle,
      'idealComparison': instance.idealComparison,
      'recommendations': instance.recommendations,
    };

T $enumDecode<T>(
  Map<T, Object> enumValues,
  Object? source, {
  T? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, source);
    },
  ).key;
}

T? $enumDecodeNullable<T>(
  Map<T, Object> enumValues,
  Object? source, {
  T? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return $enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}
