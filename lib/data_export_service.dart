// data_export_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class DataExportService {
  static Future<String> exportToCSV({
    required List<double> signal,
    required List<int> detection,
    required List<int> algorithm,
    required String filename,
  }) async {
    try {
      final buffer = StringBuffer();
      
      // CSV Header
      buffer.writeln('Timestamp,Signal,Detection,Algorithm');
      
      // Find the maximum length to handle different array sizes
      int maxLength = [signal.length, detection.length, algorithm.length]
          .reduce((a, b) => a > b ? a : b);
      
      // Write data rows
      for (int i = 0; i < maxLength; i++) {
        double timestamp = i * 0.03; // 30ms sampling period
        double signalValue = i < signal.length ? signal[i] : 0.0;
        int detectionValue = i < detection.length ? detection[i] : 0;
        int algorithmValue = i < algorithm.length ? algorithm[i] : 0;
        
        buffer.writeln('$timestamp,$signalValue,$detectionValue,$algorithmValue');
      }
      
      // For web platform, return the CSV content as string
      if (kIsWeb) {
        return buffer.toString();
      }
      
      // For desktop/mobile platforms, save to file
      final directory = Directory.current;
      final file = File('${directory.path}/$filename');
      await file.writeAsString(buffer.toString());
      
      return 'Data exported to: ${file.path}';
    } catch (e) {
      return 'Export failed: $e';
    }
  }
  
  static Map<String, dynamic> calculateStatistics({
    required List<double> signal,
    required List<int> detection,
    required List<int> algorithm,
  }) {
    if (signal.isEmpty) {
      return {
        'signalMean': 0.0,
        'signalStdDev': 0.0,
        'signalMin': 0.0,
        'signalMax': 0.0,
        'detectionCount': 0,
        'detectionDuration': 0.0,
        'algorithmAccuracy': 0.0,
      };
    }
    
    // Signal statistics
    double signalSum = signal.reduce((a, b) => a + b);
    double signalMean = signalSum / signal.length;
    
    double variance = signal
        .map((x) => (x - signalMean) * (x - signalMean))
        .reduce((a, b) => a + b) / signal.length;
    double signalStdDev = sqrt(variance);
    
    double signalMin = signal.reduce((a, b) => a < b ? a : b);
    double signalMax = signal.reduce((a, b) => a > b ? a : b);
    
    // Detection statistics
    int detectionCount = detection.where((x) => x > 0).length;
    double detectionDuration = detectionCount * 0.03; // 30ms per sample
    
    // Algorithm accuracy (comparing detection vs algorithm)
    int correctPredictions = 0;
    int minLength = detection.length < algorithm.length ? detection.length : algorithm.length;
    
    for (int i = 0; i < minLength; i++) {
      if ((detection[i] > 0 && algorithm[i] > 0) || 
          (detection[i] == 0 && algorithm[i] == 0)) {
        correctPredictions++;
      }
    }
    
    double algorithmAccuracy = minLength > 0 ? correctPredictions / minLength : 0.0;
    
    return {
      'signalMean': signalMean,
      'signalStdDev': signalStdDev,
      'signalMin': signalMin,
      'signalMax': signalMax,
      'detectionCount': detectionCount,
      'detectionDuration': detectionDuration,
      'algorithmAccuracy': algorithmAccuracy,
    };
  }
}

// Helper function for square root calculation
double sqrt(double x) {
  if (x < 0) return double.nan;
  if (x == 0) return 0;
  
  double guess = x / 2;
  double prevGuess;
  
  do {
    prevGuess = guess;
    guess = (guess + x / guess) / 2;
  } while ((guess - prevGuess).abs() > 1e-10);
  
  return guess;
}
