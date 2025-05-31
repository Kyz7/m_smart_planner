// lib/models/itinerary.dart - COMPLETE FILE

import 'dart:convert';
import 'place.dart';

class TravelPlan {
  final String? id;
  final Place place;
  final DateRange dateRange;
  final FlightInfo? flight;
  final double estimatedCost;
  final DateTime? createdAt;

  TravelPlan({
    this.id,
    required this.place,
    required this.dateRange,
    this.flight,
    required this.estimatedCost,
    this.createdAt,
  });

  factory TravelPlan.fromJson(Map<String, dynamic> json) {
    // ✅ DEBUGGING: Log incoming JSON
    print('=== TRAVEL PLAN FROM JSON ===');
    print('JSON keys: ${json.keys.toList()}');
    print('Full JSON: ${jsonEncode(json)}');
    
    try {
      // ✅ PERBAIKAN: Handle multiple possible field names
      final String? planId = json['_id'] ?? json['id'];
      
      // ✅ PERBAIKAN: Handle place data dengan lebih robust
      Map<String, dynamic> placeData;
      if (json['place'] is Map<String, dynamic>) {
        placeData = json['place'];
      } else {
        throw Exception('Invalid place data in JSON');
      }
      
      // ✅ PERBAIKAN: Handle dateRange dengan multiple possible formats
      Map<String, dynamic> dateRangeData;
      if (json.containsKey('dateRange') && json['dateRange'] != null) {
        dateRangeData = json['dateRange'];
      } else if (json.containsKey('date_range') && json['date_range'] != null) {
        dateRangeData = json['date_range'];
      } else {
        throw Exception('Missing dateRange data in JSON');
      }
      
      // ✅ PERBAIKAN: Handle estimatedCost dengan multiple possible formats
      double cost = 0.0;
      if (json.containsKey('estimatedCost') && json['estimatedCost'] != null) {
        cost = json['estimatedCost'].toDouble();
      } else if (json.containsKey('estimated_cost') && json['estimated_cost'] != null) {
        cost = json['estimated_cost'].toDouble();
      }
      
      // ✅ PERBAIKAN: Handle flight data with null check
      FlightInfo? flightInfo;
      if (json['flight'] != null && json['flight'] is Map<String, dynamic>) {
        try {
          flightInfo = FlightInfo.fromJson(json['flight']);
        } catch (e) {
          print('⚠️ Warning: Failed to parse flight data: $e');
          flightInfo = null;
        }
      }
      
      // ✅ PERBAIKAN: Handle createdAt dengan multiple formats
      DateTime? createdAt;
      if (json['createdAt'] != null) {
        try {
          createdAt = DateTime.parse(json['createdAt']);
        } catch (e) {
          print('⚠️ Warning: Failed to parse createdAt: $e');
        }
      } else if (json['created_at'] != null) {
        try {
          createdAt = DateTime.parse(json['created_at']);
        } catch (e) {
          print('⚠️ Warning: Failed to parse created_at: $e');
        }
      }
      
      final travelPlan = TravelPlan(
        id: planId,
        place: Place.fromJson(placeData),
        dateRange: DateRange.fromJson(dateRangeData),
        flight: flightInfo,
        estimatedCost: cost,
        createdAt: createdAt,
      );
      
      // ✅ DEBUGGING: Log created object
      print('✅ TravelPlan created successfully');
      print('ID: ${travelPlan.id}');
      print('Place: ${travelPlan.place.name}');
      print('DateRange: ${travelPlan.dateRange.from} - ${travelPlan.dateRange.to}');
      print('Cost: ${travelPlan.estimatedCost}');
      
      return travelPlan;
      
    } catch (error) {
      print('❌ Error creating TravelPlan from JSON: $error');
      print('JSON data: ${jsonEncode(json)}');
      rethrow;
    }
  }

  // ✅ TAMBAHKAN: Method untuk convert ke JSON (untuk debugging)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'place': place.toJson(),
      'dateRange': dateRange.toJson(),
      'flight': flight?.toJson(),
      'estimatedCost': estimatedCost,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  int get duration {
    return dateRange.to.difference(dateRange.from).inDays + 1;
  }
}

// ✅ DEFINISI CLASS DATERANGE
class DateRange {
  final DateTime from;
  final DateTime to;

  DateRange({required this.from, required this.to});

  factory DateRange.fromJson(Map<String, dynamic> json) {
    // ✅ DEBUGGING: Log DateRange parsing
    print('=== PARSING DATERANGE ===');
    print('JSON: ${jsonEncode(json)}');
    
    try {
      DateTime fromDate;
      DateTime toDate;
      
      // ✅ PERBAIKAN: Handle multiple possible field names
      if (json.containsKey('from') && json['from'] != null) {
        fromDate = DateTime.parse(json['from']);
      } else if (json.containsKey('start') && json['start'] != null) {
        fromDate = DateTime.parse(json['start']);
      } else if (json.containsKey('start_date') && json['start_date'] != null) {
        fromDate = DateTime.parse(json['start_date']);
      } else {
        throw Exception('Missing start date in DateRange JSON');
      }
      
      if (json.containsKey('to') && json['to'] != null) {
        toDate = DateTime.parse(json['to']);
      } else if (json.containsKey('end') && json['end'] != null) {
        toDate = DateTime.parse(json['end']);
      } else if (json.containsKey('end_date') && json['end_date'] != null) {
        toDate = DateTime.parse(json['end_date']);
      } else {
        throw Exception('Missing end date in DateRange JSON');
      }
      
      print('✅ DateRange parsed: $fromDate - $toDate');
      return DateRange(from: fromDate, to: toDate);
      
    } catch (error) {
      print('❌ Error parsing DateRange: $error');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    };
  }
}

// ✅ DEFINISI CLASS FLIGHTINFO
class FlightInfo {
  final String origin;
  final String destination;
  final double? price;

  FlightInfo({
    required this.origin,
    required this.destination,
    this.price,
  });

  factory FlightInfo.fromJson(Map<String, dynamic> json) {
    // ✅ DEBUGGING: Log FlightInfo parsing
    print('=== PARSING FLIGHTINFO ===');
    print('JSON: ${jsonEncode(json)}');
    
    try {
      final flightInfo = FlightInfo(
        origin: json['origin'] ?? json['from'] ?? '',
        destination: json['destination'] ?? json['to'] ?? '',
        price: json['price']?.toDouble() ?? json['cost']?.toDouble(),
      );
      
      print('✅ FlightInfo parsed: ${flightInfo.origin} → ${flightInfo.destination} (${flightInfo.price})');
      return flightInfo;
      
    } catch (error) {
      print('❌ Error parsing FlightInfo: $error');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'price': price,
    };
  }
}