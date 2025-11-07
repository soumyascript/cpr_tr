//cpr_training_app/lib/models/models.dart
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

// Enums
enum CompressionDirection { increasing, decreasing }

enum CPRPhase { compression, recoil, quietude, pause }

enum AlertType { goFaster, slowDown, beGentle, releaseMore }

// System Configuration Model
@JsonSerializable()
class SystemConfig {
  final CompressionDirection compressionDirection;
  final double maxCompressionRate;
  final double minCompressionRate;
  final int movingWindow;
  final double hysteresis;
  final double quietudePercent;
  final double maxQuietudeTime;
  final int phaseDeterminationCycles;
  final double compressionOk;
  final double compressionHi;
  final double recoilOk;
  final double recoilLow;
  final double compressionRateSmoothingFactor;
  final int compressionRateCalculationPeaks;

  const SystemConfig({
    this.compressionDirection = CompressionDirection.increasing,
    this.maxCompressionRate = 120.0,
    this.minCompressionRate = 100.0,
    this.movingWindow = 2,
    this.hysteresis = 5.0,
    this.quietudePercent = 0.1,
    this.maxQuietudeTime = 2.0,
    this.phaseDeterminationCycles = 3,
    this.compressionOk = 200.0,
    this.compressionHi = 300.0,
    this.recoilOk = 100.0,
    this.recoilLow = 150.0,
    this.compressionRateSmoothingFactor = 0.3,
    this.compressionRateCalculationPeaks = 5,
  });

  factory SystemConfig.fromJson(Map<String, dynamic> json) =>
      _$SystemConfigFromJson(json);
  Map<String, dynamic> toJson() => _$SystemConfigToJson(this);

  SystemConfig copyWith({
    CompressionDirection? compressionDirection,
    double? maxCompressionRate,
    double? minCompressionRate,
    int? movingWindow,
    double? hysteresis,
    double? quietudePercent,
    double? maxQuietudeTime,
    int? phaseDeterminationCycles,
    double? compressionOk,
    double? compressionHi,
    double? recoilOk,
    double? recoilLow,
    double? compressionRateSmoothingFactor,
    int? compressionRateCalculationPeaks,
  }) {
    return SystemConfig(
      compressionDirection: compressionDirection ?? this.compressionDirection,
      maxCompressionRate: maxCompressionRate ?? this.maxCompressionRate,
      minCompressionRate: minCompressionRate ?? this.minCompressionRate,
      movingWindow: movingWindow ?? this.movingWindow,
      hysteresis: hysteresis ?? this.hysteresis,
      quietudePercent: quietudePercent ?? this.quietudePercent,
      maxQuietudeTime: maxQuietudeTime ?? this.maxQuietudeTime,
      phaseDeterminationCycles:
          phaseDeterminationCycles ?? this.phaseDeterminationCycles,
      compressionOk: compressionOk ?? this.compressionOk,
      compressionHi: compressionHi ?? this.compressionHi,
      recoilOk: recoilOk ?? this.recoilOk,
      recoilLow: recoilLow ?? this.recoilLow,
      compressionRateSmoothingFactor:
          compressionRateSmoothingFactor ?? this.compressionRateSmoothingFactor,
      compressionRateCalculationPeaks: compressionRateCalculationPeaks ??
          this.compressionRateCalculationPeaks,
    );
  }
}

// Cloud Configuration Model
@JsonSerializable()
class CloudConfig {
  final String provider;
  final String accessKeyId;
  final String secretKey;
  final String region;
  final String bucketName;
  final String? folderPrefix;
  final int minTimeElapsed;
  final bool aiDebriefing;
  final List<String> aiDebriefingParameters;

  const CloudConfig({
    this.provider = 'AWS S3',
    this.accessKeyId = '',
    this.secretKey = '',
    this.region = '',
    this.bucketName = '',
    this.folderPrefix,
    this.minTimeElapsed = 5,
    this.aiDebriefing = false,
    this.aiDebriefingParameters = const [],
  });

  factory CloudConfig.fromJson(Map<String, dynamic> json) =>
      _$CloudConfigFromJson(json);
  Map<String, dynamic> toJson() => _$CloudConfigToJson(this);

  CloudConfig copyWith({
    String? provider,
    String? accessKeyId,
    String? secretKey,
    String? region,
    String? bucketName,
    String? folderPrefix,
    int? minTimeElapsed,
    bool? aiDebriefing,
    List<String>? aiDebriefingParameters,
  }) {
    return CloudConfig(
      provider: provider ?? this.provider,
      accessKeyId: accessKeyId ?? this.accessKeyId,
      secretKey: secretKey ?? this.secretKey,
      region: region ?? this.region,
      bucketName: bucketName ?? this.bucketName,
      folderPrefix: folderPrefix ?? this.folderPrefix,
      minTimeElapsed: minTimeElapsed ?? this.minTimeElapsed,
      aiDebriefing: aiDebriefing ?? this.aiDebriefing,
      aiDebriefingParameters:
          aiDebriefingParameters ?? this.aiDebriefingParameters,
    );
  }

  bool get isConfigured {
    return accessKeyId.isNotEmpty &&
        secretKey.isNotEmpty &&
        region.isNotEmpty &&
        bucketName.isNotEmpty;
  }
}

// Session Model
@JsonSerializable()
class CPRSession {
  final int id;
  final int sessionNumber;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationMs;
  final bool synced;
  final String? notes;
  final String appVersion;

  const CPRSession({
    required this.id,
    required this.sessionNumber,
    required this.startedAt,
    this.endedAt,
    this.durationMs,
    this.synced = false,
    this.notes,
    this.appVersion = '1.0.0',
  });

  factory CPRSession.fromJson(Map<String, dynamic> json) =>
      _$CPRSessionFromJson(json);
  Map<String, dynamic> toJson() => _$CPRSessionToJson(this);

  CPRSession copyWith({
    int? id,
    int? sessionNumber,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMs,
    bool? synced,
    String? notes,
    String? appVersion,
  }) {
    return CPRSession(
      id: id ?? this.id,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMs: durationMs ?? this.durationMs,
      synced: synced ?? this.synced,
      notes: notes ?? this.notes,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  bool get isActive => endedAt == null;
  Duration get duration => Duration(milliseconds: durationMs ?? 0);
}

// Sample Model (sensor data point)
@JsonSerializable()
class SensorSample {
  final int id;
  final int sessionId;
  final DateTime timestamp;
  final int sensor1Raw;
  final int sensor2Raw;
  final double sensor1Avg;
  final double sensor2Avg;

  const SensorSample({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    required this.sensor1Raw,
    required this.sensor2Raw,
    required this.sensor1Avg,
    required this.sensor2Avg,
  });

  factory SensorSample.fromJson(Map<String, dynamic> json) =>
      _$SensorSampleFromJson(json);
  Map<String, dynamic> toJson() => _$SensorSampleToJson(this);
}

// Event Model (for storing session events)
@JsonSerializable()
class CPREvent {
  final int id;
  final int sessionId;
  final DateTime timestamp;
  final String type;
  final Map<String, dynamic> payload;

  const CPREvent({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    required this.type,
    required this.payload,
  });

  factory CPREvent.fromJson(Map<String, dynamic> json) =>
      _$CPREventFromJson(json);
  Map<String, dynamic> toJson() => _$CPREventToJson(this);
}

// Metrics Model (current session metrics)
class CPRMetrics {
  final double? compressionRate;
  final int compressionCount;
  final int recoilCount;
  final int goodCompressions;
  final int goodRecoils;
  final int cycleNumber;
  final double? ccf;
  final CPRPhase currentPhase;

  const CPRMetrics({
    this.compressionRate,
    this.compressionCount = 0,
    this.recoilCount = 0,
    this.goodCompressions = 0,
    this.goodRecoils = 0,
    this.cycleNumber = 0,
    this.ccf,
    this.currentPhase = CPRPhase.quietude,
  });

  CPRMetrics copyWith({
    double? compressionRate,
    int? compressionCount,
    int? recoilCount,
    int? goodCompressions,
    int? goodRecoils,
    int? cycleNumber,
    double? ccf,
    CPRPhase? currentPhase,
  }) {
    return CPRMetrics(
      compressionRate: compressionRate ?? this.compressionRate,
      compressionCount: compressionCount ?? this.compressionCount,
      recoilCount: recoilCount ?? this.recoilCount,
      goodCompressions: goodCompressions ?? this.goodCompressions,
      goodRecoils: goodRecoils ?? this.goodRecoils,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      ccf: ccf ?? this.ccf,
      currentPhase: currentPhase ?? this.currentPhase,
    );
  }
}

// Alert Model
class CPRAlert {
  final AlertType type;
  final String message;
  final DateTime timestamp;
  final String? audioFile;

  const CPRAlert({
    required this.type,
    required this.message,
    required this.timestamp,
    this.audioFile,
  });

  static CPRAlert goFaster() => CPRAlert(
        type: AlertType.goFaster,
        message: 'Go faster',
        timestamp: DateTime.now(),
        audioFile: 'assets/audio/goFaster.wav',
      );

  static CPRAlert slowDown() => CPRAlert(
        type: AlertType.slowDown,
        message: 'Slow down',
        timestamp: DateTime.now(),
        audioFile: 'assets/audio/slowDown.wav',
      );

  static CPRAlert beGentle() => CPRAlert(
        type: AlertType.beGentle,
        message: 'Be gentle',
        timestamp: DateTime.now(),
        audioFile: 'assets/audio/beGentle.wav',
      );

  static CPRAlert releaseMore() => CPRAlert(
        type: AlertType.releaseMore,
        message: 'Release more',
        timestamp: DateTime.now(),
        audioFile: 'assets/audio/releaseMore.wav',
      );
}

// Graph data point
class GraphDataPoint {
  final DateTime timestamp;
  final double value;
  final Color color;

  const GraphDataPoint({
    required this.timestamp,
    required this.value,
    required this.color,
  });
}

// Debrief data
@JsonSerializable()
class DebriefData {
  final int sessionId;
  final int durationSeconds;
  final int cycleCount;
  final double averageRate;
  final double averageCCF;
  final int totalCompressions;
  final int goodCompressions;
  final int totalRecoils;
  final int goodRecoils;
  final List<int> breathsPerCycle;
  final Map<String, dynamic> idealComparison;
  final List<String> recommendations;

  const DebriefData({
    required this.sessionId,
    required this.durationSeconds,
    required this.cycleCount,
    required this.averageRate,
    required this.averageCCF,
    required this.totalCompressions,
    required this.goodCompressions,
    required this.totalRecoils,
    required this.goodRecoils,
    required this.breathsPerCycle,
    required this.idealComparison,
    required this.recommendations,
  });

  factory DebriefData.fromJson(Map<String, dynamic> json) =>
      _$DebriefDataFromJson(json);
  Map<String, dynamic> toJson() => _$DebriefDataToJson(this);

  double get compressionAccuracy => totalCompressions > 0
      ? (goodCompressions / totalCompressions) * 100
      : 0.0;

  double get recoilAccuracy =>
      totalRecoils > 0 ? (goodRecoils / totalRecoils) * 100 : 0.0;

  bool get isRateOptimal => averageRate >= 100 && averageRate <= 120;
  bool get isCCFOptimal => averageCCF >= 0.6;
}


//
// //cpr_training_app/lib/models/models.dart
// import 'package:flutter/material.dart';
// import 'package:json_annotation/json_annotation.dart';
//
// part 'models.g.dart';
//
// // Enums
// enum CompressionDirection { increasing, decreasing }
//
// enum CPRPhase { compression, recoil, quietude, pause }
//
// enum AlertType { goFaster, slowDown, beGentle, releaseMore }
//
// enum PeakTroughType { compressionPeak, recoilTrough }
//
// // System Configuration Model
// @JsonSerializable()
// class SystemConfig {
//   final CompressionDirection compressionDirection;
//   final double maxCompressionRate;
//   final double minCompressionRate;
//   final int movingWindow;
//   final double hysteresis;
//   final double quietudePercent;
//   final double maxQuietudeTime;
//   final int phaseDeterminationCycles;
//   final double compressionOk;
//   final double compressionHi;
//   final double recoilOk;
//   final double recoilLow;
//   final double compressionRateSmoothingFactor;
//   final int compressionRateCalculationPeaks;
//
//   const SystemConfig({
//     this.compressionDirection = CompressionDirection.increasing,
//     this.maxCompressionRate = 120.0,
//     this.minCompressionRate = 100.0,
//     this.movingWindow = 2,
//     this.hysteresis = 5.0,
//     this.quietudePercent = 0.1,
//     this.maxQuietudeTime = 2.0,
//     this.phaseDeterminationCycles = 3,
//     this.compressionOk = 200.0,
//     this.compressionHi = 300.0,
//     this.recoilOk = 100.0,
//     this.recoilLow = 150.0,
//     this.compressionRateSmoothingFactor = 0.3,
//     this.compressionRateCalculationPeaks = 5,
//   });
//
//   factory SystemConfig.fromJson(Map<String, dynamic> json) =>
//       _$SystemConfigFromJson(json);
//   Map<String, dynamic> toJson() => _$SystemConfigToJson(this);
//
//   SystemConfig copyWith({
//     CompressionDirection? compressionDirection,
//     double? maxCompressionRate,
//     double? minCompressionRate,
//     int? movingWindow,
//     double? hysteresis,
//     double? quietudePercent,
//     double? maxQuietudeTime,
//     int? phaseDeterminationCycles,
//     double? compressionOk,
//     double? compressionHi,
//     double? recoilOk,
//     double? recoilLow,
//     double? compressionRateSmoothingFactor,
//     int? compressionRateCalculationPeaks,
//   }) {
//     return SystemConfig(
//       compressionDirection: compressionDirection ?? this.compressionDirection,
//       maxCompressionRate: maxCompressionRate ?? this.maxCompressionRate,
//       minCompressionRate: minCompressionRate ?? this.minCompressionRate,
//       movingWindow: movingWindow ?? this.movingWindow,
//       hysteresis: hysteresis ?? this.hysteresis,
//       quietudePercent: quietudePercent ?? this.quietudePercent,
//       maxQuietudeTime: maxQuietudeTime ?? this.maxQuietudeTime,
//       phaseDeterminationCycles:
//       phaseDeterminationCycles ?? this.phaseDeterminationCycles,
//       compressionOk: compressionOk ?? this.compressionOk,
//       compressionHi: compressionHi ?? this.compressionHi,
//       recoilOk: recoilOk ?? this.recoilOk,
//       recoilLow: recoilLow ?? this.recoilLow,
//       compressionRateSmoothingFactor:
//       compressionRateSmoothingFactor ?? this.compressionRateSmoothingFactor,
//       compressionRateCalculationPeaks: compressionRateCalculationPeaks ??
//           this.compressionRateCalculationPeaks,
//     );
//   }
// }
//
// // Sensor Data Point (used by graph and processing)
// class SensorDataPoint {
//   final DateTime timestamp;
//   final double value;
//
//   const SensorDataPoint(this.timestamp, this.value);
// }
//
// // Peak/Trough Model
// class PeakTrough {
//   final DateTime timestamp;
//   final double value;
//   final PeakTroughType type;
//   final bool isGood;
//
//   const PeakTrough({
//     required this.timestamp,
//     required this.value,
//     required this.type,
//     required this.isGood,
//   });
// }
//
// // Phase Change Event
// class PhaseChangeEvent {
//   final DateTime timestamp;
//   final CPRPhase fromPhase;
//   final CPRPhase toPhase;
//   final double value;
//
//   const PhaseChangeEvent({
//     required this.timestamp,
//     required this.fromPhase,
//     required this.toPhase,
//     required this.value,
//   });
// }
//
// // Peak Trough Event
// class PeakTroughEvent {
//   final PeakTrough peak;
//
//   const PeakTroughEvent({required this.peak});
// }
//
// // Cloud Configuration Model
// @JsonSerializable()
// class CloudConfig {
//   final String provider;
//   final String accessKeyId;
//   final String secretKey;
//   final String region;
//   final String bucketName;
//   final String? folderPrefix;
//   final int minTimeElapsed;
//   final bool aiDebriefing;
//   final List<String> aiDebriefingParameters;
//
//   const CloudConfig({
//     this.provider = 'AWS S3',
//     this.accessKeyId = '',
//     this.secretKey = '',
//     this.region = '',
//     this.bucketName = '',
//     this.folderPrefix,
//     this.minTimeElapsed = 5,
//     this.aiDebriefing = false,
//     this.aiDebriefingParameters = const [],
//   });
//
//   factory CloudConfig.fromJson(Map<String, dynamic> json) =>
//       _$CloudConfigFromJson(json);
//   Map<String, dynamic> toJson() => _$CloudConfigToJson(this);
//
//   CloudConfig copyWith({
//     String? provider,
//     String? accessKeyId,
//     String? secretKey,
//     String? region,
//     String? bucketName,
//     String? folderPrefix,
//     int? minTimeElapsed,
//     bool? aiDebriefing,
//     List<String>? aiDebriefingParameters,
//   }) {
//     return CloudConfig(
//       provider: provider ?? this.provider,
//       accessKeyId: accessKeyId ?? this.accessKeyId,
//       secretKey: secretKey ?? this.secretKey,
//       region: region ?? this.region,
//       bucketName: bucketName ?? this.bucketName,
//       folderPrefix: folderPrefix ?? this.folderPrefix,
//       minTimeElapsed: minTimeElapsed ?? this.minTimeElapsed,
//       aiDebriefing: aiDebriefing ?? this.aiDebriefing,
//       aiDebriefingParameters:
//       aiDebriefingParameters ?? this.aiDebriefingParameters,
//     );
//   }
//
//   bool get isConfigured {
//     return accessKeyId.isNotEmpty &&
//         secretKey.isNotEmpty &&
//         region.isNotEmpty &&
//         bucketName.isNotEmpty;
//   }
// }
//
// // Session Model
// @JsonSerializable()
// class CPRSession {
//   final int id;
//   final int sessionNumber;
//   final DateTime startedAt;
//   final DateTime? endedAt;
//   final int? durationMs;
//   final bool synced;
//   final String? notes;
//   final String appVersion;
//
//   const CPRSession({
//     required this.id,
//     required this.sessionNumber,
//     required this.startedAt,
//     this.endedAt,
//     this.durationMs,
//     this.synced = false,
//     this.notes,
//     this.appVersion = '1.0.0',
//   });
//
//   factory CPRSession.fromJson(Map<String, dynamic> json) =>
//       _$CPRSessionFromJson(json);
//   Map<String, dynamic> toJson() => _$CPRSessionToJson(this);
//
//   CPRSession copyWith({
//     int? id,
//     int? sessionNumber,
//     DateTime? startedAt,
//     DateTime? endedAt,
//     int? durationMs,
//     bool? synced,
//     String? notes,
//     String? appVersion,
//   }) {
//     return CPRSession(
//       id: id ?? this.id,
//       sessionNumber: sessionNumber ?? this.sessionNumber,
//       startedAt: startedAt ?? this.startedAt,
//       endedAt: endedAt ?? this.endedAt,
//       durationMs: durationMs ?? this.durationMs,
//       synced: synced ?? this.synced,
//       notes: notes ?? this.notes,
//       appVersion: appVersion ?? this.appVersion,
//     );
//   }
//
//   bool get isActive => endedAt == null;
//   Duration get duration => Duration(milliseconds: durationMs ?? 0);
// }
//
// // Sample Model (sensor data point)
// @JsonSerializable()
// class SensorSample {
//   final int id;
//   final int sessionId;
//   final DateTime timestamp;
//   final int sensor1Raw;
//   final int sensor2Raw;
//   final double sensor1Avg;
//   final double sensor2Avg;
//
//   const SensorSample({
//     required this.id,
//     required this.sessionId,
//     required this.timestamp,
//     required this.sensor1Raw,
//     required this.sensor2Raw,
//     required this.sensor1Avg,
//     required this.sensor2Avg,
//   });
//
//   factory SensorSample.fromJson(Map<String, dynamic> json) =>
//       _$SensorSampleFromJson(json);
//   Map<String, dynamic> toJson() => _$SensorSampleToJson(this);
// }
//
// // Event Model (for storing session events)
// @JsonSerializable()
// class CPREvent {
//   final int id;
//   final int sessionId;
//   final DateTime timestamp;
//   final String type;
//   final Map<String, dynamic> payload;
//
//   const CPREvent({
//     required this.id,
//     required this.sessionId,
//     required this.timestamp,
//     required this.type,
//     required this.payload,
//   });
//
//   factory CPREvent.fromJson(Map<String, dynamic> json) =>
//       _$CPREventFromJson(json);
//   Map<String, dynamic> toJson() => _$CPREventToJson(this);
// }
//
// // Metrics Model (current session metrics)
// class CPRMetrics {
//   final double? compressionRate;
//   final int compressionCount;
//   final int recoilCount;
//   final int goodCompressions;
//   final int goodRecoils;
//   final int cycleNumber;
//   final double? ccf;
//   final CPRPhase currentPhase;
//
//   const CPRMetrics({
//     this.compressionRate,
//     this.compressionCount = 0,
//     this.recoilCount = 0,
//     this.goodCompressions = 0,
//     this.goodRecoils = 0,
//     this.cycleNumber = 0,
//     this.ccf,
//     this.currentPhase = CPRPhase.quietude,
//   });
//
//   CPRMetrics copyWith({
//     double? compressionRate,
//     int? compressionCount,
//     int? recoilCount,
//     int? goodCompressions,
//     int? goodRecoils,
//     int? cycleNumber,
//     double? ccf,
//     CPRPhase? currentPhase,
//   }) {
//     return CPRMetrics(
//       compressionRate: compressionRate ?? this.compressionRate,
//       compressionCount: compressionCount ?? this.compressionCount,
//       recoilCount: recoilCount ?? this.recoilCount,
//       goodCompressions: goodCompressions ?? this.goodCompressions,
//       goodRecoils: goodRecoils ?? this.goodRecoils,
//       cycleNumber: cycleNumber ?? this.cycleNumber,
//       ccf: ccf ?? this.ccf,
//       currentPhase: currentPhase ?? this.currentPhase,
//     );
//   }
// }
//
// // Alert Model
// class CPRAlert {
//   final AlertType type;
//   final String message;
//   final DateTime timestamp;
//   final String? audioFile;
//
//   const CPRAlert({
//     required this.type,
//     required this.message,
//     required this.timestamp,
//     this.audioFile,
//   });
//
//   static CPRAlert goFaster() => CPRAlert(
//     type: AlertType.goFaster,
//     message: 'Go faster',
//     timestamp: DateTime.now(),
//     audioFile: 'assets/audio/goFaster.wav',
//   );
//
//   static CPRAlert slowDown() => CPRAlert(
//     type: AlertType.slowDown,
//     message: 'Slow down',
//     timestamp: DateTime.now(),
//     audioFile: 'assets/audio/slowDown.wav',
//   );
//
//   static CPRAlert beGentle() => CPRAlert(
//     type: AlertType.beGentle,
//     message: 'Be gentle',
//     timestamp: DateTime.now(),
//     audioFile: 'assets/audio/beGentle.wav',
//   );
//
//   static CPRAlert releaseMore() => CPRAlert(
//     type: AlertType.releaseMore,
//     message: 'Release more',
//     timestamp: DateTime.now(),
//     audioFile: 'assets/audio/releaseMore.wav',
//   );
// }
//
// // Graph data point
// class GraphDataPoint {
//   final DateTime timestamp;
//   final double value;
//   final Color color;
//
//   const GraphDataPoint({
//     required this.timestamp,
//     required this.value,
//     required this.color,
//   });
// }
//
// // Debrief data
// @JsonSerializable()
// class DebriefData {
//   final int sessionId;
//   final int durationSeconds;
//   final int cycleCount;
//   final double averageRate;
//   final double averageCCF;
//   final int totalCompressions;
//   final int goodCompressions;
//   final int totalRecoils;
//   final int goodRecoils;
//   final List<int> breathsPerCycle;
//   final Map<String, dynamic> idealComparison;
//   final List<String> recommendations;
//
//   const DebriefData({
//     required this.sessionId,
//     required this.durationSeconds,
//     required this.cycleCount,
//     required this.averageRate,
//     required this.averageCCF,
//     required this.totalCompressions,
//     required this.goodCompressions,
//     required this.totalRecoils,
//     required this.goodRecoils,
//     required this.breathsPerCycle,
//     required this.idealComparison,
//     required this.recommendations,
//   });
//
//   factory DebriefData.fromJson(Map<String, dynamic> json) =>
//       _$DebriefDataFromJson(json);
//   Map<String, dynamic> toJson() => _$DebriefDataToJson(this);
//
//   double get compressionAccuracy => totalCompressions > 0
//       ? (goodCompressions / totalCompressions) * 100
//       : 0.0;
//
//   double get recoilAccuracy =>
//       totalRecoils > 0 ? (goodRecoils / totalRecoils) * 100 : 0.0;
//
//   bool get isRateOptimal => averageRate >= 100 && averageRate <= 120;
//   bool get isCCFOptimal => averageCCF >= 0.6;
// }
//
// // Replay-specific models
// enum TimelineMarkerType { alert, cycle, pause }
//
// class TimelineMarker {
//   final Duration position;
//   final TimelineMarkerType type;
//   final String label;
//
//   const TimelineMarker({
//     required this.position,
//     required this.type,
//     required this.label,
//   });
// }
// );
// }
//
// class ReplayData {
//   final CPRMetrics metrics;
//   final CPRAlert? alert;
//   final List<GraphDataPoint> sensor1Data;
//   final List<GraphDataPoint> sensor2Data;
//
//   const ReplayData({
//     required this.metrics,
//     this.alert,
//     required this.sensor1Data,
//     required this.sensor2Data,
//   });
// }