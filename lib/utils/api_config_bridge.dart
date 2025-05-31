// This file serves as a bridge between the old ApiConfig and the new EnvConfig
// This ensures backward compatibility with existing code

import 'env_config.dart';

class ApiConfig {
  // Delegate to EnvConfig for values
  static String get vertexProjectId => EnvConfig.vertexProjectId;
  static String get vertexRegion => EnvConfig.vertexRegion;
  static String get vertexServiceAccountKeyPath => EnvConfig.vertexServiceAccountKeyPath;
}
