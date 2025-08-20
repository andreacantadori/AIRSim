class CommonDefines {
  // Sampling period in ms
  static const int SAMPLING_PERIOD = 30;

  // Number of points in the graph
  static const int N_GRAPH_POINTS = 1000;

  // Graph limits along the y-axis
  static const double GRAPH_MIN_VALUE = 0;
  static const double GRAPH_MAX_VALUE = 3000;

  // Grid lines in the graph
  static const int N_HORIZONTAL_GRID_LINES = 10;
  static const int N_VERTICAL_GRID_LINES = 10;

  // Offsets of the curves in the graph (for visualization purpose only)
  static const double OFFSET_DETECTION = 10;
  static const double OFFSET_ALGORITHM = 300;

  // Amplification factors of the curves in the graph (for visualization purpose only)
  static const double AMPLI_SIGNAL = 1;
  static const double AMPLI_DETECTION = 100;
  static const double AMPLI_ALGORITHM = 100;

  // Thermal drift simulation
  static const double THERMAL_DRIFT_AMPL = 200;
  static const double THERMAL_DRIFT_FREQ = 0.005;

  // Random noise
  static const double NOISE_AMPL = 10;

  // AIR signal features
  static const double AIR_AMPLITUDE_MIN = 50;      // digits (C2T units)
  static const double AIR_AMPLITUDE_MAX = 300;     // digits (C2T units)
  static const int AIR_DURATION_MIN = 300;         // ms
  static const int AIR_DURATION_MAX = 2000;        // ms
  static const int AIR_SLOPE_MIN = 50;             // ms
  static const int AIR_SLOPE_MAX = 60000;          // ms
  static const double AIR_OBSTACLE = 300;          // Amplitude of obstacle (in C2T units)
  static const double AIR_OFFSET = 1500;
}