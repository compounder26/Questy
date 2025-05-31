import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

class EnvConfig {
  // Default fallback values (can be overridden)
  static String vertexProjectId = 'your-default-project-id';
  static String vertexRegion = 'us-central1';
  static String vertexServiceAccountKeyPath = 'lib/config/vertex_ai_credentials.json';
  
  static bool _initialized = false;
  
  // Load configuration from environment or assets
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Try to load from a bundled configuration JSON if available
      final String configJson = await rootBundle.loadString('assets/env_config.json');
      final Map<String, dynamic> config = json.decode(configJson);
      
      // Override defaults with values from config file
      vertexProjectId = config['vertexProjectId'] ?? vertexProjectId;
      vertexRegion = config['vertexRegion'] ?? vertexRegion;
      vertexServiceAccountKeyPath = config['vertexServiceAccountKeyPath'] ?? vertexServiceAccountKeyPath;
      
      developer.log('Environment configuration loaded successfully from assets.', name: 'EnvConfig');
      developer.log('Project ID: $vertexProjectId, Region: $vertexRegion', name: 'EnvConfig');
      
      // Verify service account key file exists
      try {
        await rootBundle.loadString(vertexServiceAccountKeyPath);
        developer.log('Service account key file loaded successfully', name: 'EnvConfig');
      } catch (e) {
        developer.log('⚠️ Service account key file not found: $e', name: 'EnvConfig', error: e);
        // Move credentials file path to assets directory as fallback
        vertexServiceAccountKeyPath = 'assets/vertex_ai_credentials.json';
        try {
          await rootBundle.loadString(vertexServiceAccountKeyPath);
          developer.log('Service account key file loaded from fallback location', name: 'EnvConfig');
        } catch (e) {
          developer.log('⚠️ Service account key file not found in fallback location either', name: 'EnvConfig', error: e);
        }
      }
    } catch (e) {
      developer.log('Using default environment configuration: $e', name: 'EnvConfig', error: e);
      // Continue with default values if config file not found
    }
    
    _initialized = true;
  }
}
