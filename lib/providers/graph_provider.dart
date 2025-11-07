// //cpr_training_app/lib/providers/graph_provider.dart
// import 'dart:collection';
// import 'dart:math' as math;
// //import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import '../models/models.dart';
// import '../services/sensor_service.dart';
//
// class GraphProvider with ChangeNotifier {
//   static const int maxDataPoints = 500; // ~25 seconds at 20Hz
//   static const Duration timeWindow = Duration(seconds: 30);
//
//   final Queue<GraphDataPoint> _sensor1Data = Queue();
//   final Queue<GraphDataPoint> _sensor2Data = Queue();
//
//   // Configuration
//   bool _showSensor1 = true;
//   bool _showSensor2 = false;
//   double _timeSpanSeconds = 30.0;
//   SystemConfig? _systemConfig;
//
//   // Getters
//   Queue<GraphDataPoint> get sensor1Data => _sensor1Data;
//   Queue<GraphDataPoint> get sensor2Data => _sensor2Data;
//   List<GraphDataPoint> get dataPoints =>
//       List.from(_sensor1Data); // Added missing getter
//   bool get showSensor1 => _showSensor1;
//   bool get showSensor2 => _showSensor2;
//   double get timeSpanSeconds => _timeSpanSeconds;
//   int get sensor1DataCount => _sensor1Data.length;
//   int get sensor2DataCount => _sensor2Data.length;
//
//   // Update system config for quality color coding
//   void updateSystemConfig(SystemConfig config) {
//     _systemConfig = config;
//   }
//
//   // Add sensor data point
//   void addDataPoint(SensorData data) {
//     final timestamp = data.timestamp;
//
//     // Add sensor1 data with quality color coding
//     final sensor1Color = _getSensor1Color(data.sensor1Raw);
//     _sensor1Data.add(GraphDataPoint(
//       timestamp: timestamp,
//       value: data.sensor1Raw.toDouble(),
//       color: sensor1Color,
//     ));
//
//     // Add sensor2 data (breath sensor)
//     _sensor2Data.add(GraphDataPoint(
//       timestamp: timestamp,
//       value: data.sensor2Raw.toDouble(),
//       color: Colors.blue,
//     ));
//
//     // Maintain buffer size
//     _maintainBufferSize();
//
//     notifyListeners();
//   }
//
//   // Get color for sensor1 based on CPR quality
//   Color _getSensor1Color(int value) {
//     if (_systemConfig == null) {
//       // Use default values if config not available
//       return _getDefaultSensor1Color(value);
//     }
//
//     final compressionOk = _systemConfig!.compressionOk;
//     final compressionHi = _systemConfig!.compressionHi;
//     final recoilOk = _systemConfig!.recoilOk;
//     final recoilLow = _systemConfig!.recoilLow;
//
//     // Good compression range
//     if (value >= compressionOk && value <= compressionHi) {
//       return Colors.green; // Good compression
//     }
//     // Poor recoil
//     else if (value < recoilLow) {
//       return Colors.red; // Incomplete recoil
//     }
//     // Good recoil
//     else if (value >= recoilOk && value < compressionOk) {
//       return Colors.yellow; // Good recoil
//     }
//     // Bad compression (too deep or too shallow)
//     else {
//       return Colors.red; // Bad compression/recoil
//     }
//   }
//
//   // Default color coding when config not available
//   Color _getDefaultSensor1Color(int value) {
//     const compressionOk = 200.0;
//     const compressionHi = 800.0;
//     const recoilOk = 100.0;
//     const recoilLow = 50.0;
//
//     if (value >= compressionOk && value <= compressionHi) {
//       return Colors.green;
//     } else if (value < recoilLow) {
//       return Colors.red;
//     } else if (value >= recoilOk) {
//       return Colors.yellow;
//     } else {
//       return Colors.red;
//     }
//   }
//
//   // Maintain buffer size within limits
//   void _maintainBufferSize() {
//     final now = DateTime.now();
//     final cutoffTime =
//         now.subtract(Duration(seconds: _timeSpanSeconds.toInt()));
//
//     // Remove old data points beyond time window
//     while (_sensor1Data.isNotEmpty &&
//         _sensor1Data.first.timestamp.isBefore(cutoffTime)) {
//       _sensor1Data.removeFirst();
//     }
//
//     while (_sensor2Data.isNotEmpty &&
//         _sensor2Data.first.timestamp.isBefore(cutoffTime)) {
//       _sensor2Data.removeFirst();
//     }
//
//     // Also maintain max data points limit
//     while (_sensor1Data.length > maxDataPoints) {
//       _sensor1Data.removeFirst();
//     }
//
//     while (_sensor2Data.length > maxDataPoints) {
//       _sensor2Data.removeFirst();
//     }
//   }
//
//   // Configure which sensors to show
//   void setSensorVisibility({bool? sensor1, bool? sensor2}) {
//     if (sensor1 != null) _showSensor1 = sensor1;
//     if (sensor2 != null) _showSensor2 = sensor2;
//     notifyListeners();
//     debugPrint('Graph visibility: S1=$_showSensor1, S2=$_showSensor2');
//   }
//
//   // Set time span for graph
//   void setTimeSpan(double seconds) {
//     _timeSpanSeconds = seconds.clamp(10.0, 120.0); // 10 seconds to 2 minutes
//     _maintainBufferSize(); // Clean up data outside new window
//     notifyListeners();
//     debugPrint('Graph time span set to ${_timeSpanSeconds}s');
//   }
//
//   // Clear all data
//   void clearData() {
//     _sensor1Data.clear();
//     _sensor2Data.clear();
//     notifyListeners();
//     debugPrint('Graph data cleared');
//   }
//
//   // Get data for specific time range
//   List<GraphDataPoint> getSensor1DataInRange(DateTime start, DateTime end) {
//     return _sensor1Data
//         .where((point) =>
//             point.timestamp.isAfter(start) && point.timestamp.isBefore(end))
//         .toList();
//   }
//
//   List<GraphDataPoint> getSensor2DataInRange(DateTime start, DateTime end) {
//     return _sensor2Data
//         .where((point) =>
//             point.timestamp.isAfter(start) && point.timestamp.isBefore(end))
//         .toList();
//   }
//
//   // Get statistics for current data
//   GraphStatistics getGraphStatistics() {
//     if (_sensor1Data.isEmpty) {
//       return const GraphStatistics(
//         sensor1Min: 0,
//         sensor1Max: 0,
//         sensor1Avg: 0,
//         sensor2Min: 0,
//         sensor2Max: 0,
//         sensor2Avg: 0,
//         dataPoints: 0,
//         timeSpan: Duration.zero,
//       );
//     }
//
//     final sensor1Values = _sensor1Data.map((p) => p.value).toList();
//     final sensor2Values = _sensor2Data.map((p) => p.value).toList();
//
//     final timeSpan = _sensor1Data.isNotEmpty
//         ? _sensor1Data.last.timestamp.difference(_sensor1Data.first.timestamp)
//         : Duration.zero;
//
//     return GraphStatistics(
//       sensor1Min: sensor1Values.reduce((a, b) => a < b ? a : b),
//       sensor1Max: sensor1Values.reduce((a, b) => a > b ? a : b),
//       sensor1Avg: sensor1Values.reduce((a, b) => a + b) / sensor1Values.length,
//       sensor2Min: sensor2Values.isNotEmpty
//           ? sensor2Values.reduce((a, b) => a < b ? a : b)
//           : 0,
//       sensor2Max: sensor2Values.isNotEmpty
//           ? sensor2Values.reduce((a, b) => a > b ? a : b)
//           : 0,
//       sensor2Avg: sensor2Values.isNotEmpty
//           ? sensor2Values.reduce((a, b) => a + b) / sensor2Values.length
//           : 0,
//       dataPoints: _sensor1Data.length,
//       timeSpan: timeSpan,
//     );
//   }
//
//   // Get data rate (samples per second)
//   double get currentDataRate {
//     if (_sensor1Data.length < 2) return 0.0;
//
//     final timeSpan = _sensor1Data.last.timestamp
//             .difference(_sensor1Data.first.timestamp)
//             .inMilliseconds /
//         1000.0;
//
//     if (timeSpan <= 0) return 0.0;
//
//     return _sensor1Data.length / timeSpan;
//   }
//
//   // Check if data is flowing
//   bool get isDataFlowing {
//     if (_sensor1Data.isEmpty) return false;
//
//     final lastDataTime = _sensor1Data.last.timestamp;
//     final timeSinceLastData = DateTime.now().difference(lastDataTime);
//
//     return timeSinceLastData.inSeconds <
//         5; // Consider flowing if data within 5 seconds
//   }
//
//   // Get latest sensor values
//   double? get latestSensor1Value =>
//       _sensor1Data.isNotEmpty ? _sensor1Data.last.value : null;
//
//   double? get latestSensor2Value =>
//       _sensor2Data.isNotEmpty ? _sensor2Data.last.value : null;
//
//   // Get min/max values for chart scaling
//   double get sensor1Min {
//     if (_sensor1Data.isEmpty) return 0;
//     return _sensor1Data.map((p) => p.value).reduce((a, b) => a < b ? a : b);
//   }
//
//   double get sensor1Max {
//     if (_sensor1Data.isEmpty) return 1023;
//     return _sensor1Data.map((p) => p.value).reduce((a, b) => a > b ? a : b);
//   }
//
//   double get sensor2Min {
//     if (_sensor2Data.isEmpty) return 0;
//     return _sensor2Data.map((p) => p.value).reduce((a, b) => a < b ? a : b);
//   }
//
//   double get sensor2Max {
//     if (_sensor2Data.isEmpty) return 1023;
//     return _sensor2Data.map((p) => p.value).reduce((a, b) => a > b ? a : b);
//   }
//
//   // Export graph data as CSV
//   String exportGraphDataAsCSV() {
//     final buffer = StringBuffer();
//     buffer.writeln('Timestamp,Sensor1,Sensor2');
//
//     final maxLength = math.max(_sensor1Data.length, _sensor2Data.length);
//
//     for (int i = 0; i < maxLength; i++) {
//       final sensor1Point =
//           i < _sensor1Data.length ? _sensor1Data.elementAt(i) : null;
//       final sensor2Point =
//           i < _sensor2Data.length ? _sensor2Data.elementAt(i) : null;
//
//       final timestamp =
//           sensor1Point?.timestamp ?? sensor2Point?.timestamp ?? DateTime.now();
//       final sensor1Value = sensor1Point?.value ?? '';
//       final sensor2Value = sensor2Point?.value ?? '';
//
//       buffer.writeln(
//           '${timestamp.toIso8601String()},$sensor1Value,$sensor2Value');
//     }
//
//     return buffer.toString();
//   }
//
//   // Get graph data for export with time relative to session start
//   String exportGraphDataWithRelativeTime(DateTime sessionStart) {
//     final buffer = StringBuffer();
//     buffer.writeln('RelativeTimeSeconds,Sensor1,Sensor2');
//
//     final maxLength = math.max(_sensor1Data.length, _sensor2Data.length);
//
//     for (int i = 0; i < maxLength; i++) {
//       final sensor1Point =
//           i < _sensor1Data.length ? _sensor1Data.elementAt(i) : null;
//       final sensor2Point =
//           i < _sensor2Data.length ? _sensor2Data.elementAt(i) : null;
//
//       final timestamp =
//           sensor1Point?.timestamp ?? sensor2Point?.timestamp ?? DateTime.now();
//       final relativeSeconds =
//           timestamp.difference(sessionStart).inMilliseconds / 1000.0;
//       final sensor1Value = sensor1Point?.value ?? '';
//       final sensor2Value = sensor2Point?.value ?? '';
//
//       buffer.writeln('$relativeSeconds,$sensor1Value,$sensor2Value');
//     }
//
//     return buffer.toString();
//   }
//
//   // Add multiple data points (for replay)
//   void addMultipleDataPoints(List<SensorData> dataPoints) {
//     for (final data in dataPoints) {
//       final timestamp = data.timestamp;
//
//       _sensor1Data.add(GraphDataPoint(
//         timestamp: timestamp,
//         value: data.sensor1Raw.toDouble(),
//         color: _getSensor1Color(data.sensor1Raw),
//       ));
//
//       _sensor2Data.add(GraphDataPoint(
//         timestamp: timestamp,
//         value: data.sensor2Raw.toDouble(),
//         color: Colors.blue,
//       ));
//     }
//
//     _maintainBufferSize();
//     notifyListeners();
//   }
//
//   // Get color distribution (for quality analysis)
//   Map<Color, int> getSensor1ColorDistribution() {
//     final distribution = <Color, int>{};
//
//     for (final point in _sensor1Data) {
//       distribution[point.color] = (distribution[point.color] ?? 0) + 1;
//     }
//
//     return distribution;
//   }
//
//   // Calculate quality percentages
//   Map<String, double> getQualityPercentages() {
//     if (_sensor1Data.isEmpty) return {'good': 0.0, 'warning': 0.0, 'bad': 0.0};
//
//     int goodCount = 0;
//     int warningCount = 0;
//     int badCount = 0;
//
//     for (final point in _sensor1Data) {
//       if (point.color == Colors.green) {
//         goodCount++;
//       } else if (point.color == Colors.yellow) {
//         warningCount++;
//       } else if (point.color == Colors.red) {
//         badCount++;
//       }
//     }
//
//     final total = _sensor1Data.length;
//     return {
//       'good': (goodCount / total) * 100,
//       'warning': (warningCount / total) * 100,
//       'bad': (badCount / total) * 100,
//     };
//   }
// }
//
// // Supporting classes
// class GraphStatistics {
//   final double sensor1Min;
//   final double sensor1Max;
//   final double sensor1Avg;
//   final double sensor2Min;
//   final double sensor2Max;
//   final double sensor2Avg;
//   final int dataPoints;
//   final Duration timeSpan;
//
//   const GraphStatistics({
//     required this.sensor1Min,
//     required this.sensor1Max,
//     required this.sensor1Avg,
//     required this.sensor2Min,
//     required this.sensor2Max,
//     required this.sensor2Avg,
//     required this.dataPoints,
//     required this.timeSpan,
//   });
//
//   @override
//   String toString() {
//     return 'GraphStatistics('
//         'S1: ${sensor1Min.toInt()}-${sensor1Max.toInt()} (avg: ${sensor1Avg.toInt()}), '
//         'S2: ${sensor2Min.toInt()}-${sensor2Max.toInt()} (avg: ${sensor2Avg.toInt()}), '
//         'Points: $dataPoints, Span: ${timeSpan.inSeconds}s'
//         ')';
//   }
// }



//cpr_training_app/lib/providers/graph_provider.dart
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/sensor_service.dart' as sensor; // Use prefix to avoid conflict

class GraphProvider with ChangeNotifier {
  static const int maxDataPoints = 500; // ~25 seconds at 20Hz
  static const Duration timeWindow = Duration(seconds: 30);

  final Queue<GraphDataPoint> _sensor1Data = Queue();
  final Queue<GraphDataPoint> _sensor2Data = Queue();

  // Configuration
  bool _showSensor1 = true;
  bool _showSensor2 = false;
  double _timeSpanSeconds = 30.0;
  SystemConfig? _systemConfig;

  // Getters
  Queue<GraphDataPoint> get sensor1Data => _sensor1Data;
  Queue<GraphDataPoint> get sensor2Data => _sensor2Data;
  List<GraphDataPoint> get dataPoints => List.from(_sensor1Data);
  bool get showSensor1 => _showSensor1;
  bool get showSensor2 => _showSensor2;
  double get timeSpanSeconds => _timeSpanSeconds;
  int get sensor1DataCount => _sensor1Data.length;
  int get sensor2DataCount => _sensor2Data.length;

  // Update system config for quality color coding
  void updateSystemConfig(SystemConfig config) {
    _systemConfig = config;
  }

  // Add sensor data point - UPDATED to work with CSV sensor data
  void addDataPoint(sensor.SensorData data) {
    final timestamp = data.timestamp;

    // Add sensor1 data with quality color coding (using depth)
    final sensor1Color = _getSensor1Color(data.compressionDepth);
    _sensor1Data.add(GraphDataPoint(
      timestamp: timestamp,
      value: data.compressionDepth,
      color: sensor1Color,
    ));

    // Add sensor2 data (tilt data - can use TiltX or TiltY)
    _sensor2Data.add(GraphDataPoint(
      timestamp: timestamp,
      value: data.tiltX, // Using tiltX as sensor2 data
      color: Colors.blue,
    ));

    // Maintain buffer size
    _maintainBufferSize();

    notifyListeners();
  }

  // Get color for sensor1 based on CPR quality (depth in mm)
  Color _getSensor1Color(double depth) {
    if (_systemConfig == null) {
      return _getDefaultSensor1Color(depth);
    }

    // For depth-based coloring: 50-60mm is good
    if (depth >= 50.0 && depth <= 60.0) {
      return Colors.green; // Good compression depth
    } else if (depth > 60.0) {
      return Colors.red; // Too deep
    } else if (depth >= 40.0 && depth < 50.0) {
      return Colors.yellow; // Slightly shallow
    } else if (depth < 5.0) {
      return Colors.grey; // No compression
    } else {
      return Colors.orange; // Too shallow
    }
  }

  // Default color coding when config not available
  Color _getDefaultSensor1Color(double depth) {
    if (depth >= 50.0 && depth <= 60.0) {
      return Colors.green;
    } else if (depth > 60.0) {
      return Colors.red;
    } else if (depth >= 40.0) {
      return Colors.yellow;
    } else if (depth < 5.0) {
      return Colors.grey;
    } else {
      return Colors.orange;
    }
  }

  // Maintain buffer size within limits
  void _maintainBufferSize() {
    final now = DateTime.now();
    final cutoffTime =
    now.subtract(Duration(seconds: _timeSpanSeconds.toInt()));

    // Remove old data points beyond time window
    while (_sensor1Data.isNotEmpty &&
        _sensor1Data.first.timestamp.isBefore(cutoffTime)) {
      _sensor1Data.removeFirst();
    }

    while (_sensor2Data.isNotEmpty &&
        _sensor2Data.first.timestamp.isBefore(cutoffTime)) {
      _sensor2Data.removeFirst();
    }

    // Also maintain max data points limit
    while (_sensor1Data.length > maxDataPoints) {
      _sensor1Data.removeFirst();
    }

    while (_sensor2Data.length > maxDataPoints) {
      _sensor2Data.removeFirst();
    }
  }

  // Configure which sensors to show
  void setSensorVisibility({bool? sensor1, bool? sensor2}) {
    if (sensor1 != null) _showSensor1 = sensor1;
    if (sensor2 != null) _showSensor2 = sensor2;
    notifyListeners();
    debugPrint('Graph visibility: S1=$_showSensor1, S2=$_showSensor2');
  }

  // Set time span for graph
  void setTimeSpan(double seconds) {
    _timeSpanSeconds = seconds.clamp(10.0, 120.0); // 10 seconds to 2 minutes
    _maintainBufferSize(); // Clean up data outside new window
    notifyListeners();
    debugPrint('Graph time span set to ${_timeSpanSeconds}s');
  }

  // Clear all data
  void clearData() {
    _sensor1Data.clear();
    _sensor2Data.clear();
    notifyListeners();
    debugPrint('Graph data cleared');
  }

  // Get data for specific time range
  List<GraphDataPoint> getSensor1DataInRange(DateTime start, DateTime end) {
    return _sensor1Data
        .where((point) =>
    point.timestamp.isAfter(start) && point.timestamp.isBefore(end))
        .toList();
  }

  List<GraphDataPoint> getSensor2DataInRange(DateTime start, DateTime end) {
    return _sensor2Data
        .where((point) =>
    point.timestamp.isAfter(start) && point.timestamp.isBefore(end))
        .toList();
  }

  // Get statistics for current data
  GraphStatistics getGraphStatistics() {
    if (_sensor1Data.isEmpty) {
      return const GraphStatistics(
        sensor1Min: 0,
        sensor1Max: 0,
        sensor1Avg: 0,
        sensor2Min: 0,
        sensor2Max: 0,
        sensor2Avg: 0,
        dataPoints: 0,
        timeSpan: Duration.zero,
      );
    }

    final sensor1Values = _sensor1Data.map((p) => p.value).toList();
    final sensor2Values = _sensor2Data.map((p) => p.value).toList();

    final timeSpan = _sensor1Data.isNotEmpty
        ? _sensor1Data.last.timestamp.difference(_sensor1Data.first.timestamp)
        : Duration.zero;

    return GraphStatistics(
      sensor1Min: sensor1Values.reduce((a, b) => a < b ? a : b),
      sensor1Max: sensor1Values.reduce((a, b) => a > b ? a : b),
      sensor1Avg: sensor1Values.reduce((a, b) => a + b) / sensor1Values.length,
      sensor2Min: sensor2Values.isNotEmpty
          ? sensor2Values.reduce((a, b) => a < b ? a : b)
          : 0,
      sensor2Max: sensor2Values.isNotEmpty
          ? sensor2Values.reduce((a, b) => a > b ? a : b)
          : 0,
      sensor2Avg: sensor2Values.isNotEmpty
          ? sensor2Values.reduce((a, b) => a + b) / sensor2Values.length
          : 0,
      dataPoints: _sensor1Data.length,
      timeSpan: timeSpan,
    );
  }

  // Get data rate (samples per second)
  double get currentDataRate {
    if (_sensor1Data.length < 2) return 0.0;

    final timeSpan = _sensor1Data.last.timestamp
        .difference(_sensor1Data.first.timestamp)
        .inMilliseconds /
        1000.0;

    if (timeSpan <= 0) return 0.0;

    return _sensor1Data.length / timeSpan;
  }

  // Check if data is flowing
  bool get isDataFlowing {
    if (_sensor1Data.isEmpty) return false;

    final lastDataTime = _sensor1Data.last.timestamp;
    final timeSinceLastData = DateTime.now().difference(lastDataTime);

    return timeSinceLastData.inSeconds < 5;
  }

  // Get latest sensor values
  double? get latestSensor1Value =>
      _sensor1Data.isNotEmpty ? _sensor1Data.last.value : null;

  double? get latestSensor2Value =>
      _sensor2Data.isNotEmpty ? _sensor2Data.last.value : null;

  // Get min/max values for chart scaling
  double get sensor1Min {
    if (_sensor1Data.isEmpty) return 0;
    return _sensor1Data.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  }

  double get sensor1Max {
    if (_sensor1Data.isEmpty) return 100; // Default max for depth in mm
    return _sensor1Data.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  }

  double get sensor2Min {
    if (_sensor2Data.isEmpty) return -20;
    return _sensor2Data.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  }

  double get sensor2Max {
    if (_sensor2Data.isEmpty) return 20;
    return _sensor2Data.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  }

  // Export graph data as CSV
  String exportGraphDataAsCSV() {
    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Depth,TiltX');

    final maxLength = math.max(_sensor1Data.length, _sensor2Data.length);

    for (int i = 0; i < maxLength; i++) {
      final sensor1Point =
      i < _sensor1Data.length ? _sensor1Data.elementAt(i) : null;
      final sensor2Point =
      i < _sensor2Data.length ? _sensor2Data.elementAt(i) : null;

      final timestamp =
          sensor1Point?.timestamp ?? sensor2Point?.timestamp ?? DateTime.now();
      final sensor1Value = sensor1Point?.value ?? '';
      final sensor2Value = sensor2Point?.value ?? '';

      buffer.writeln(
          '${timestamp.toIso8601String()},$sensor1Value,$sensor2Value');
    }

    return buffer.toString();
  }

  // Get graph data for export with time relative to session start
  String exportGraphDataWithRelativeTime(DateTime sessionStart) {
    final buffer = StringBuffer();
    buffer.writeln('RelativeTimeSeconds,Depth,TiltX');

    final maxLength = math.max(_sensor1Data.length, _sensor2Data.length);

    for (int i = 0; i < maxLength; i++) {
      final sensor1Point =
      i < _sensor1Data.length ? _sensor1Data.elementAt(i) : null;
      final sensor2Point =
      i < _sensor2Data.length ? _sensor2Data.elementAt(i) : null;

      final timestamp =
          sensor1Point?.timestamp ?? sensor2Point?.timestamp ?? DateTime.now();
      final relativeSeconds =
          timestamp.difference(sessionStart).inMilliseconds / 1000.0;
      final sensor1Value = sensor1Point?.value ?? '';
      final sensor2Value = sensor2Point?.value ?? '';

      buffer.writeln('$relativeSeconds,$sensor1Value,$sensor2Value');
    }

    return buffer.toString();
  }

  // Add multiple data points (for replay)
  void addMultipleDataPoints(List<sensor.SensorData> dataPoints) {
    for (final data in dataPoints) {
      final timestamp = data.timestamp;

      _sensor1Data.add(GraphDataPoint(
        timestamp: timestamp,
        value: data.compressionDepth,
        color: _getSensor1Color(data.compressionDepth),
      ));

      _sensor2Data.add(GraphDataPoint(
        timestamp: timestamp,
        value: data.tiltX,
        color: Colors.blue,
      ));
    }

    _maintainBufferSize();
    notifyListeners();
  }

  // Get color distribution (for quality analysis)
  Map<Color, int> getSensor1ColorDistribution() {
    final distribution = <Color, int>{};

    for (final point in _sensor1Data) {
      distribution[point.color] = (distribution[point.color] ?? 0) + 1;
    }

    return distribution;
  }

  // Calculate quality percentages
  Map<String, double> getQualityPercentages() {
    if (_sensor1Data.isEmpty) return {'good': 0.0, 'warning': 0.0, 'bad': 0.0};

    int goodCount = 0;
    int warningCount = 0;
    int badCount = 0;

    for (final point in _sensor1Data) {
      if (point.color == Colors.green) {
        goodCount++;
      } else if (point.color == Colors.yellow || point.color == Colors.orange) {
        warningCount++;
      } else if (point.color == Colors.red) {
        badCount++;
      }
    }

    final total = _sensor1Data.length;
    return {
      'good': (goodCount / total) * 100,
      'warning': (warningCount / total) * 100,
      'bad': (badCount / total) * 100,
    };
  }
}

// Supporting classes
class GraphStatistics {
  final double sensor1Min;
  final double sensor1Max;
  final double sensor1Avg;
  final double sensor2Min;
  final double sensor2Max;
  final double sensor2Avg;
  final int dataPoints;
  final Duration timeSpan;

  const GraphStatistics({
    required this.sensor1Min,
    required this.sensor1Max,
    required this.sensor1Avg,
    required this.sensor2Min,
    required this.sensor2Max,
    required this.sensor2Avg,
    required this.dataPoints,
    required this.timeSpan,
  });

  @override
  String toString() {
    return 'GraphStatistics('
        'S1: ${sensor1Min.toInt()}-${sensor1Max.toInt()} (avg: ${sensor1Avg.toInt()}), '
        'S2: ${sensor2Min.toInt()}-${sensor2Max.toInt()} (avg: ${sensor2Avg.toInt()}), '
        'Points: $dataPoints, Span: ${timeSpan.inSeconds}s'
        ')';
  }
}