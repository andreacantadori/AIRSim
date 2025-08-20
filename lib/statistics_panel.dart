// statistics_panel.dart
import 'package:flutter/material.dart';
import 'data_export_service.dart';

class StatisticsPanel extends StatelessWidget {
  final List<double> signal;
  final List<int> detection;
  final List<int> algorithm;

  const StatisticsPanel({
    Key? key,
    required this.signal,
    required this.detection,
    required this.algorithm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = DataExportService.calculateStatistics(
      signal: signal,
      detection: detection,
      algorithm: algorithm,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Real-time Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow('Signal Mean', '${stats['signalMean'].toStringAsFixed(2)}'),
          _buildStatRow('Signal Std Dev', '${stats['signalStdDev'].toStringAsFixed(2)}'),
          _buildStatRow('Signal Range', '${stats['signalMin'].toStringAsFixed(1)} - ${stats['signalMax'].toStringAsFixed(1)}'),
          const Divider(height: 20),
          _buildStatRow('Detections', '${stats['detectionCount']}'),
          _buildStatRow('Detection Time', '${stats['detectionDuration'].toStringAsFixed(2)}s'),
          _buildStatRow('Algorithm Accuracy', '${(stats['algorithmAccuracy'] * 100).toStringAsFixed(1)}%'),
          const SizedBox(height: 12),
          _buildAccuracyIndicator(stats['algorithmAccuracy']),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyIndicator(double accuracy) {
    Color indicatorColor;
    String status;
    
    if (accuracy >= 0.9) {
      indicatorColor = Colors.green;
      status = 'Excellent';
    } else if (accuracy >= 0.8) {
      indicatorColor = Colors.orange;
      status = 'Good';
    } else if (accuracy >= 0.7) {
      indicatorColor = Colors.yellow.shade700;
      status = 'Fair';
    } else {
      indicatorColor = Colors.red;
      status = 'Poor';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance: $status',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: indicatorColor,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: accuracy,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
      ],
    );
  }
}
