import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'screens/config_screen.dart';

// Define a class to hold call information
class CallData {
  final String phoneNumber;
  final String direction;
  final String lineStatus;
  final String extensionName;
  final DateTime timestamp;
  final Map<String, dynamic> rawData;

  CallData({
    required this.phoneNumber,
    required this.direction,
    required this.lineStatus,
    required this.extensionName,
    required this.timestamp,
    required this.rawData,
  });

  Map<String, dynamic> toJson() => {
    'phoneNumber': phoneNumber,
    'direction': direction,
    'lineStatus': lineStatus,
    'extensionName': extensionName,
    'timestamp': timestamp.toIso8601String(),
    'rawData': rawData,
  };
}

// Event types for the monitor
enum TelavoxEvent { newCall, callEnded, error, statusUpdate }

class TelavoxMonitor {
  //final Config config;
  final Logger logger;
  Timer? _pollTimer;
  final Map<String, DateTime> _recentCalls = {};
  Set<String> _previousActiveCalls = {};
  final Config config;
  // Stream controller for emitting call events
  final _eventController =
      StreamController<Map<TelavoxEvent, dynamic>>.broadcast();

  Stream<Map<TelavoxEvent, dynamic>> get events => _eventController.stream;

  TelavoxMonitor({required this.config, required this.logger});

  Future<void> checkForNewCalls() async {
    try {
      final response = await http.get(
        Uri.parse('${config.telavoxBaseUrl}/extensions'),
        headers: {
          'Authorization': 'Bearer ${config.telavoxJwtToken}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> extensions = json.decode(response.body);
        Set<String> currentActiveCalls = {};

        for (var extension in extensions) {
          final calls = extension['calls'] as List<dynamic>;
          for (var call in calls) {
            if (call['direction'] == 'in' && call['linestatus'] == 'up') {
              final callerNumber = call['callerid'] as String;
              currentActiveCalls.add(callerNumber);

              if (!_previousActiveCalls.contains(callerNumber)) {
                if (!isNumberExempted(callerNumber)) {
                  logger.info(
                    'New call from $callerNumber to ${extension['name']}',
                  );
                  _recentCalls[callerNumber] = DateTime.now();

                  // Create and emit call data
                  final callData = CallData(
                    phoneNumber: callerNumber,
                    direction: call['direction'],
                    lineStatus: call['linestatus'],
                    extensionName: extension['name'],
                    timestamp: DateTime.now(),
                    rawData: call,
                  );

                  _eventController.add({TelavoxEvent.newCall: callData});
                }
              }
            }
          }
        }

        // Check for ended calls
        for (String number in _previousActiveCalls) {
          if (!currentActiveCalls.contains(number)) {
            _eventController.add({TelavoxEvent.callEnded: number});
          }
        }

        _previousActiveCalls = currentActiveCalls;
      } else if (response.statusCode == 401) {
        logger.severe('Authentication failed. Check JWT token.');
        _eventController.add({TelavoxEvent.error: 'Authentication failed'});
        stopMonitoring();
      }
    } catch (e) {
      logger.severe('Error checking calls: $e');
      _eventController.add({TelavoxEvent.error: e.toString()});
    }
  }

  bool isNumberExempted(String number) {
    if (!_recentCalls.containsKey(number)) return false;

    if (DateTime.now().difference(_recentCalls[number]!).inMinutes >=
        config.telavoxExemptionTime) {
      _recentCalls.remove(number);
      return false;
    }
    return true;
  }

  void startMonitoring() {
    logger.info('Starting Telavox monitoring');
    _eventController.add({TelavoxEvent.statusUpdate: 'Monitoring started'});
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(seconds: config.telavoxPollInterval),
      (_) => checkForNewCalls(),
    );
  }

  void stopMonitoring() {
    _pollTimer?.cancel();
    _eventController.add({TelavoxEvent.statusUpdate: 'Monitoring stopped'});
    logger.info('Monitoring stopped');
  }

  Future<void> dispose() async {
    await _eventController.close();
    stopMonitoring();
  }
}

// Example usage in another project:
void exampleUsage() async {
  //File('path/to/config.json')
  final config = Config();
  final logger = Logger('TelavoxMonitor');
  final monitor = TelavoxMonitor(config: config, logger: logger);

  // Subscribe to events
  monitor.events.listen((event) {
    if (event.containsKey(TelavoxEvent.newCall)) {
      final callData = event[TelavoxEvent.newCall] as CallData;
      print('New call from: ${callData.phoneNumber}');
      print('Extension: ${callData.extensionName}');
      // Process call data as needed
    } else if (event.containsKey(TelavoxEvent.callEnded)) {
      final phoneNumber = event[TelavoxEvent.callEnded] as String;
      print('Call ended: $phoneNumber');
    }
  });

  monitor.startMonitoring();
}
