import 'package:flutter/material.dart';

class ProfileTopStatTab {
  const ProfileTopStatTab({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class ProfileMetricData {
  const ProfileMetricData({
    required this.weekly,
    required this.monthly,
    required this.unit,
    required this.yAxisMax,
    required this.decimalPlaces,
    required this.changePercent,
  });

  final List<double> weekly;
  final List<double> monthly;
  final String unit;
  final double yAxisMax;
  final int decimalPlaces;
  final int changePercent;
}

String formatProfileMetricValue(double value, ProfileMetricData metric) {
  if (metric.decimalPlaces > 0) {
    return value.toStringAsFixed(metric.decimalPlaces);
  }
  return value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}

String formatProfileAxisLabel(double value, ProfileMetricData metric) {
  if (metric.decimalPlaces == 0) {
    return value.round().toString();
  }
  return value.toStringAsFixed(metric.decimalPlaces);
}
