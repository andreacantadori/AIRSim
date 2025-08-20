// main_window.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'signal_simulator.dart';
import 'signal_graph_view.dart';
import 'common_defines.dart';
import 'data_export_service.dart';
import 'statistics_panel.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  _MainWindowState createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  late SignalSimulator signalSimulator;
  Timer? simulationTimer;
  bool isRunning = false;
  bool isDetection = false;
  
  // UI state
  bool crossingEnabled = true;
  bool driftEnabled = false;
  double sensitivity = 4.0;
  double minOutputDuration = 2.0;
  double maxOutputDuration = 10.0;
  double offsetAdjust = -10.526315789473671;
  
  // Data arrays for the graph
  List<double> signal = [];
  List<int> detection = [];
  List<int> algorithm = [];
  List<double> delta = [];

  @override
  void initState() {
    super.initState();
    _initializeSimulator();
  }

  void _initializeSimulator() {
    signalSimulator = SignalSimulator();
    signalSimulator.obstacle = false;
    signalSimulator.crossing = crossingEnabled;
    signalSimulator.drift = driftEnabled;
    signalSimulator.airAmplitudeMin = CommonDefines.AIR_AMPLITUDE_MIN;
    signalSimulator.airAmplitudeMax = CommonDefines.AIR_AMPLITUDE_MAX;
    signalSimulator.offset = offsetAdjust.round();
    
    // Initialize data arrays
    for (int i = 0; i < CommonDefines.N_GRAPH_POINTS; i++) {
      signal.add(0);
      detection.add(0);
      algorithm.add(0);
      delta.add(0);
    }
  }

  void _startStopSimulation() {
    setState(() {
      if (isRunning) {
        _stopSimulation();
      } else {
        isRunning = true;
        simulationTimer = Timer.periodic(
          const Duration(milliseconds: CommonDefines.SAMPLING_PERIOD),
          (_) => _updateSimulation(),
        );
      }
    });
  }

  void _stopSimulation() {
    isRunning = false;
    simulationTimer?.cancel();
    simulationTimer = null;
  }

  void _updateSimulation() {
    double simulationValue = signalSimulator.generateSignalAtTime(signalSimulator.timeStep);
    
    setState(() {
      // Add to signal array
      signal.add(simulationValue);
      if (signal.length > CommonDefines.N_GRAPH_POINTS) {
        signal.removeAt(0);
      }
      
      // Add to detection array
      if (signalSimulator.isTarget && signalSimulator.crossing) {
        detection.add(1);
      } else {
        detection.add(0);
      }
      
      if (detection.length > CommonDefines.N_GRAPH_POINTS) {
        detection.removeAt(0);
      }
      
      // Add to algorithm array (synchronized with other arrays)
      algorithm.add(_latestAlgorithmOutput);
      if (algorithm.length > CommonDefines.N_GRAPH_POINTS) {
        algorithm.removeAt(0);
      }
      
      signalSimulator.timeStep += (CommonDefines.SAMPLING_PERIOD / 1000.0);
    });
  }

  int _latestAlgorithmOutput = 0;

  void _onAlgorithmOutput(int output) {
    _latestAlgorithmOutput = output;
  }

  void _onDetectionChanged(bool detectionState) {
    // This callback is now just used to update the LED state
    setState(() {
      isDetection = detectionState;
    });
  }

  Future<void> _exportData() async {
    if (signal.isEmpty) {
      _showMessage('No data to export. Start the simulation first.');
      return;
    }

    try {
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      String filename = 'air_simulator_data_$timestamp.csv';
      
      String result = await DataExportService.exportToCSV(
        signal: signal,
        detection: detection,
        algorithm: algorithm,
        filename: filename,
      );
      
      _showMessage(result);
    } catch (e) {
      _showMessage('Export failed: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildLED(bool isActive, Color activeColor) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? activeColor : Colors.black,
        border: Border.all(color: Colors.grey, width: 1),
      ),
    );
  }

  Widget _buildControlSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    String? minLabel,
    String? maxLabel,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.orange)),
        Row(
          children: [
            if (minLabel != null) 
              Text(minLabel, style: const TextStyle(color: Colors.orange, fontSize: 12)),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
                activeColor: Colors.orange,
              ),
            ),
            if (maxLabel != null)
              Text(maxLabel, style: const TextStyle(color: Colors.orange, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 2,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopSimulation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIR Simulator'),
        backgroundColor: Colors.blue,
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Main content area
              Expanded(
                child: Row(
                  children: [
                    // Left side - Graph
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Graph area
                          Expanded(
                            child: SignalGraphView(
                              signal: signal,
                              detection: detection,
                              algorithm: algorithm,
                              isCrossing: crossingEnabled,
                              sensitivity: sensitivity * 10,
                              minOutputPulseDuration: minOutputDuration.round(),
                              maxOutputPulseDuration: maxOutputDuration.round(),
                              onDetectionChanged: _onDetectionChanged,
                              onAlgorithmOutput: _onAlgorithmOutput,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Bottom controls
                          Row(
                            children: [
                              Switch(
                                value: crossingEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    crossingEnabled = value;
                                    signalSimulator.crossing = value;
                                  });
                                },
                              ),
                              const Text('Passaggio'),
                              const SizedBox(width: 32),
                              Switch(
                                value: driftEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    driftEnabled = value;
                                    signalSimulator.drift = value;
                                  });
                                },
                              ),
                              const Text('Drift'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Right side - Controls and Legend
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Legend
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendItem('Segnale AIR', Colors.blue),
                                _buildLegendItem('Ground truth', Colors.red),
                                _buildLegendItem('Detection', Colors.green),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // LEDs and Start/Stop
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildLED(signalSimulator.isTarget, Colors.red),
                              _buildLED(isDetection, Colors.green),
                              ElevatedButton(
                                onPressed: _startStopSimulation,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: Text(isRunning ? 'Stop' : 'Start'),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Statistics Panel
                          StatisticsPanel(
                            signal: signal,
                            detection: detection,
                            algorithm: algorithm,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Export Button
                          ElevatedButton.icon(
                            onPressed: _exportData,
                            icon: const Icon(Icons.download),
                            label: const Text('Export CSV'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Control sliders
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildControlSlider(
                                    label: 'Sensitivity',
                                    value: sensitivity,
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    minLabel: '1 (min)',
                                    maxLabel: '10 (max)',
                                    onChanged: (value) {
                                      setState(() {
                                        sensitivity = value;
                                      });
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  _buildControlSlider(
                                    label: 'Min. output duration',
                                    value: minOutputDuration,
                                    min: 0,
                                    max: 10,
                                    divisions: 10,
                                    minLabel: '0 s',
                                    maxLabel: '10 s',
                                    onChanged: (value) {
                                      setState(() {
                                        if (value < maxOutputDuration) {
                                          minOutputDuration = value;
                                        }
                                      });
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  _buildControlSlider(
                                    label: 'Max. output duration',
                                    value: maxOutputDuration,
                                    min: 0,
                                    max: 60,
                                    divisions: 12,
                                    minLabel: '0 s (dis.)',
                                    maxLabel: '60 s',
                                    onChanged: (value) {
                                      setState(() {
                                        maxOutputDuration = value;
                                      });
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  _buildControlSlider(
                                    label: 'Offset',
                                    value: offsetAdjust,
                                    min: -200,
                                    max: 200,
                                    divisions: 20,
                                    minLabel: '-200',
                                    maxLabel: '+200',
                                    onChanged: (value) {
                                      setState(() {
                                        offsetAdjust = value;
                                        signalSimulator.offset = value.round();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
