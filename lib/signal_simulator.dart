// signal_simulator.dart
import 'dart:math';
import 'common_defines.dart';

class SignalSimulator {
  double timeStep = 0;
  List<double> targetSignal = [];
  bool isTarget = false;
  
  double airAmplitudeMin = CommonDefines.AIR_AMPLITUDE_MIN;
  double airAmplitudeMax = CommonDefines.AIR_AMPLITUDE_MAX;
  bool obstacle = false;
  bool drift = false;
  bool crossing = false;
  int offset = 0;
  
  final Random _random = Random();
  int _minTimeBetweenPulses = 0;

  SignalSimulator() {
    obstacle = false;
    crossing = true;
    drift = false;
  }

  double generateSignalAtTime(double time) {
    // Thermal drift
    double thermalDrift = CommonDefines.THERMAL_DRIFT_AMPL * 
        sin(2 * pi * CommonDefines.THERMAL_DRIFT_FREQ * time);

    // Random noise (uniform distribution)
    double currentNoise = (2 * _random.nextDouble() - 1) * CommonDefines.NOISE_AMPL;

    // Randomly generated detection signal
    double randomTime = _random.nextDouble();
    
    if (_minTimeBetweenPulses > 0) {
      _minTimeBetweenPulses -= CommonDefines.SAMPLING_PERIOD;
    }
    
    if (randomTime > 0.99 && targetSignal.isEmpty && _minTimeBetweenPulses == 0) {
      _minTimeBetweenPulses = 0;
      // Generate signal
      int randomAmpl = (airAmplitudeMin + 
          (airAmplitudeMax - airAmplitudeMin) * _random.nextDouble()).round();
      double randomSign = _random.nextDouble() < 0.2 ? -1.0 : 1.0;
      
      int randomDuration = (CommonDefines.AIR_DURATION_MIN + 
          (CommonDefines.AIR_DURATION_MAX - CommonDefines.AIR_DURATION_MIN) * 
          _random.nextDouble()).round();
      int randomSlope = (CommonDefines.AIR_SLOPE_MIN + 
          (CommonDefines.AIR_SLOPE_MAX - CommonDefines.AIR_SLOPE_MIN) * 
          _random.nextDouble()).round();
      
      // Limit the slope to 1/3 of the whole pulse duration
      if (randomSlope >= randomDuration / 3) {
        randomSlope = (randomDuration / 3).round();
      }
      
      double pulse = 0;
      double deltaSlope = (randomAmpl / randomSlope) * CommonDefines.SAMPLING_PERIOD.toDouble();
      double t = 0;
      int i = 0;
      
      do {
        if (t < randomSlope) {
          pulse += deltaSlope;
          if (pulse > randomAmpl) pulse = randomAmpl.toDouble();
        } else if (t > randomDuration - randomSlope) {
          pulse -= deltaSlope;
          if (pulse < 0) pulse = 0;
        } else {
          pulse = randomAmpl.toDouble();
        }
        
        targetSignal.add(pulse * randomSign);
        if (targetSignal.length > 500) {
          targetSignal.removeAt(0);
        }
        
        ++i;
        t = i * CommonDefines.SAMPLING_PERIOD.toDouble();
      } while (t < randomDuration);
    }

    timeStep = time;
    double totalSignal = currentNoise + CommonDefines.AIR_OFFSET + offset;
    
    if (drift) {
      totalSignal += thermalDrift;
    }
    
    if (targetSignal.isNotEmpty) {
      if (crossing) {
        totalSignal += targetSignal[0];
      }
      targetSignal.removeAt(0);
      isTarget = true;
    } else {
      isTarget = false;
    }

    return totalSignal;
  }
}