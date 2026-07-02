import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  HealthService({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  Future<HealthStepResult> readTodaySteps({required int fallbackSteps}) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      return HealthStepResult(
        steps: fallbackSteps,
        source: 'dashboard',
        permissionGranted: false,
      );
    }

    await _configure();
    final authorized = await requestStepAuthorization();
    if (!authorized) {
      throw Exception(
        Platform.isIOS
            ? 'Apple Health permission is required to read watch steps.'
            : 'Health Connect permission is required to read watch steps.',
      );
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final steps = await _readSteps(startOfDay, now);

    return HealthStepResult(
      steps: math.max(fallbackSteps, steps),
      source: Platform.isIOS ? 'apple_health' : 'health_connect',
      permissionGranted: true,
    );
  }

  Future<bool> requestStepAuthorization() async {
    if (Platform.isAndroid) {
      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted) return false;
    }

    const types = [HealthDataType.STEPS];
    const permissions = [HealthDataAccess.READ];

    final hasPermissions = await _health.hasPermissions(
      types,
      permissions: permissions,
    );
    if (hasPermissions == true) return true;

    return _health.requestAuthorization(types, permissions: permissions);
  }

  Future<int> _readSteps(DateTime startTime, DateTime endTime) async {
    final total = await _health.getTotalStepsInInterval(
      startTime,
      endTime,
      includeManualEntry: false,
    );
    if (total != null) return total;

    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.STEPS],
      startTime: startTime,
      endTime: endTime,
    );

    return points.fold<int>(0, (sum, point) {
      final value = point.value;
      if (value is NumericHealthValue) {
        return sum + value.numericValue.round();
      }
      return sum;
    });
  }

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }
}

class HealthStepResult {
  const HealthStepResult({
    required this.steps,
    required this.source,
    required this.permissionGranted,
  });

  final int steps;
  final String source;
  final bool permissionGranted;
}
