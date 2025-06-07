import 'dart:convert';

class Itinerary {
  final int id;
  final int userId;
  final Map<String, dynamic> place;
  final Map<String, dynamic> dateRange;
  final double? estimatedCost;
  final Map<String, dynamic>? weather;
  final Map<String, dynamic>? flight;
  final Map<String, dynamic>? travelers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? user;

  Itinerary({
    required this.id,
    required this.userId,
    required this.place,
    required this.dateRange,
    this.estimatedCost,
    this.weather,
    this.flight,
    this.travelers,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    try {
      print('Converting itinerary data: $json');
      
      return Itinerary(
        id: json['id'] as int,
        userId: json['userId'] as int,
        place: _parseJsonField(json['place']),
        dateRange: _parseJsonField(json['dateRange']),
        estimatedCost: _parseDoubleField(json['estimatedCost']),
        weather: json['weather'] != null 
            ? _parseJsonField(json['weather']) 
            : null,
        flight: json['flight'] != null 
            ? _parseJsonField(json['flight']) 
            : null,
        travelers: json['travelers'] != null 
            ? _parseJsonField(json['travelers']) 
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        user: json['user'] != null 
            ? _parseJsonField(json['user']) 
            : null,
      );
    } catch (e, stackTrace) {
      print('Error converting itinerary data: $e');
      print('Stack trace: $stackTrace');
      print('Problematic JSON: $json');
      
      // Try to identify which field is causing the issue
      _debugParseFields(json);
      
      rethrow;
    }
  }

  // New helper method to safely parse double values
  static double? _parseDoubleField(dynamic value) {
    if (value == null) {
      return null;
    }
    
    if (value is double) {
      return value;
    }
    
    if (value is int) {
      return value.toDouble();
    }
    
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing double from string: $value');
        return null;
      }
    }
    
    if (value is num) {
      return value.toDouble();
    }
    
    print('Unexpected type for double field: ${value.runtimeType} = $value');
    return null;
  }

  // Enhanced helper method to parse JSON fields with better error handling
  static Map<String, dynamic> _parseJsonField(dynamic field) {
    if (field == null) {
      return {};
    }
    
    if (field is Map<String, dynamic>) {
      return field;
    }
    
    if (field is Map) {
      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      return Map<String, dynamic>.from(field);
    }
    
    if (field is String) {
      if (field.trim().isEmpty) {
        return {};
      }
      
      try {
        final decoded = jsonDecode(field);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        } else {
          print('Warning: JSON string decoded to non-Map type: ${decoded.runtimeType}');
          return {};
        }
      } catch (e) {
        print('Error parsing JSON string: $field');
        print('Parse error: $e');
        return {};
      }
    }
    
    print('Unexpected field type: ${field.runtimeType} for value: $field');
    return {};
  }

  // Debug method to identify problematic fields
  static void _debugParseFields(Map<String, dynamic> json) {
    final fieldsToCheck = ['place', 'dateRange', 'weather', 'flight', 'travelers', 'user'];
    
    for (String fieldName in fieldsToCheck) {
      if (json.containsKey(fieldName) && json[fieldName] != null) {
        final field = json[fieldName];
        print('Field "$fieldName": ${field.runtimeType} = $field');
        
        try {
          _parseJsonField(field);
          print('✅ Field "$fieldName" parsed successfully');
        } catch (e) {
          print('❌ Field "$fieldName" failed to parse: $e');
        }
      }
    }
    
    // Also check estimatedCost
    if (json.containsKey('estimatedCost') && json['estimatedCost'] != null) {
      final field = json['estimatedCost'];
      print('Field "estimatedCost": ${field.runtimeType} = $field');
      
      try {
        final parsed = _parseDoubleField(field);
        print('✅ Field "estimatedCost" parsed successfully: $parsed');
      } catch (e) {
        print('❌ Field "estimatedCost" failed to parse: $e');
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'place': place,
      'dateRange': dateRange,
      'estimatedCost': estimatedCost,
      'weather': weather,
      'flight': flight,
      'travelers': travelers,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'user': user,
    };
  }

  // Helper method to safely get nested values with fallbacks
  String get placeName => place['name'] ?? 'Destinasi Tidak Dikenal';
  String? get placeAddress => place['address'] ?? place['formatted_address'];
  double? get placeRating => _parseDoubleField(place['rating']);
  String? get placePhoto => place['photo'];
  
  String get dateFrom => dateRange['from'] ?? '';
  String get dateTo => dateRange['to'] ?? '';
  
  int get adultsCount => travelers?['adults'] ?? 1;
  int get childrenCount => travelers?['children'] ?? 0;
  
  String? get flightOrigin => flight?['origin'];
  String? get flightDestination => flight?['destination'];
  double? get flightCost => _parseDoubleField(flight?['cost']);

  @override
  String toString() {
    return 'Itinerary(id: $id, place: ${place['name']}, dateRange: $dateRange)';
  }
}