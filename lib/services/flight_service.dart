import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FlightService {
  static const String _baseUrl = 'YOUR_API_BASE_URL'; // Replace with your actual API URL
  static const Duration _timeout = Duration(seconds: 30);

  // Headers untuk request
  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    
    return headers;
  }

  static Future<List<Flight>> getFlightEstimate(String fromCode, String toCode) async {
    try {
      debugPrint('Fetching flight estimate from $fromCode to $toCode');
      
      final url = Uri.parse('$_baseUrl/api/flight/estimate');
      final body = json.encode({
        'from': fromCode,
        'to': toCode,
      });

      final response = await http.post(
        url,
        headers: _headers,
        body: body,
      ).timeout(_timeout);

      debugPrint('Flight API response status: ${response.statusCode}');
      debugPrint('Flight API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['flights'] != null && data['flights'] is List) {
          final List<dynamic> flightsJson = data['flights'];
          return flightsJson.map((json) => Flight.fromJson(json)).toList();
        } else {
          throw Exception('Invalid flight data format');
        }
      } else if (response.statusCode == 404) {
        throw Exception('No flights found for this route');
      } else {
        throw Exception('Failed to fetch flight data: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('Error in getFlightEstimate: $e');
      throw Exception('Failed to fetch flight data: $e');
    }
  }

  /// Alternative method to get flight data with more parameters
  static Future<FlightEstimateResponse> getDetailedFlightEstimate({
    required String fromCode,
    required String toCode,
    DateTime? departureDate,
    DateTime? returnDate,
    int passengers = 1,
    String cabinClass = 'economy',
  }) async {
    try {
      debugPrint('Fetching detailed flight estimate from $fromCode to $toCode');
      
      final url = Uri.parse('$_baseUrl/api/flight/estimate/detailed');
      final body = json.encode({
        'from': fromCode,
        'to': toCode,
        'departure_date': departureDate?.toIso8601String(),
        'return_date': returnDate?.toIso8601String(),
        'passengers': passengers,
        'cabin_class': cabinClass,
      });

      final response = await http.post(
        url,
        headers: _headers,
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FlightEstimateResponse.fromJson(data);
      } else {
        throw Exception('Failed to fetch detailed flight data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getDetailedFlightEstimate: $e');
      rethrow;
    }
  }

  /// Get popular flight routes
  static Future<List<FlightRoute>> getPopularRoutes() async {
    try {
      final url = Uri.parse('$_baseUrl/api/flight/routes/popular');
      
      final response = await http.get(
        url,
        headers: _headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'] is List) {
          final List<dynamic> routesJson = data['routes'];
          return routesJson.map((json) => FlightRoute.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting popular routes: $e');
      return [];
    }
  }

  /// Search flights with more flexible parameters
  static Future<List<Flight>> searchFlights({
    required String origin,
    required String destination,
    DateTime? departureDate,
    DateTime? returnDate,
    int adults = 1,
    int children = 0,
    int infants = 0,
    String? preferredAirline,
    String sortBy = 'price', // price, duration, departure_time
  }) async {
    try {
      final queryParams = <String, String>{
        'origin': origin,
        'destination': destination,
        'adults': adults.toString(),
        'children': children.toString(),
        'infants': infants.toString(),
        'sort_by': sortBy,
      };

      if (departureDate != null) {
        queryParams['departure_date'] = departureDate.toIso8601String().split('T')[0];
      }
      if (returnDate != null) {
        queryParams['return_date'] = returnDate.toIso8601String().split('T')[0];
      }
      if (preferredAirline != null) {
        queryParams['airline'] = preferredAirline;
      }

      final uri = Uri.parse('$_baseUrl/api/flight/search').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flights'] != null && data['flights'] is List) {
          final List<dynamic> flightsJson = data['flights'];
          return flightsJson.map((json) => Flight.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error searching flights: $e');
      return [];
    }
  }
}

/// Flight model classes
class Flight {
  final String flightNumber;
  final String airline;
  final FlightTime departure;
  final FlightTime arrival;
  final String status;
  final double? price;
  final String? aircraft;
  final int? duration; // in minutes
  final List<String>? stops;

  Flight({
    required this.flightNumber,
    required this.airline,
    required this.departure,
    required this.arrival,
    required this.status,
    this.price,
    this.aircraft,
    this.duration,
    this.stops,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      flightNumber: json['flight_number'] ?? '',
      airline: json['airline'] ?? '',
      departure: FlightTime.fromJson(json['departure'] ?? {}),
      arrival: FlightTime.fromJson(json['arrival'] ?? {}),
      status: json['status'] ?? 'unknown',
      price: json['price']?.toDouble(),
      aircraft: json['aircraft'],
      duration: json['duration']?.toInt(),
      stops: json['stops'] != null 
          ? List<String>.from(json['stops']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flight_number': flightNumber,
      'airline': airline,
      'departure': departure.toJson(),
      'arrival': arrival.toJson(),
      'status': status,
      'price': price,
      'aircraft': aircraft,
      'duration': duration,
      'stops': stops,
    };
  }
}

class FlightTime {
  final DateTime scheduled;
  final DateTime? actual;
  final String iata;
  final String? terminal;
  final String? gate;

  FlightTime({
    required this.scheduled,
    this.actual,
    required this.iata,
    this.terminal,
    this.gate,
  });

  factory FlightTime.fromJson(Map<String, dynamic> json) {
    return FlightTime(
      scheduled: DateTime.parse(json['scheduled'] ?? DateTime.now().toIso8601String()),
      actual: json['actual'] != null ? DateTime.parse(json['actual']) : null,
      iata: json['iata'] ?? '',
      terminal: json['terminal'],
      gate: json['gate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheduled': scheduled.toIso8601String(),
      'actual': actual?.toIso8601String(),
      'iata': iata,
      'terminal': terminal,
      'gate': gate,
    };
  }
}

class FlightEstimateResponse {
  final List<Flight> flights;
  final double? minPrice;
  final double? maxPrice;
  final double? averagePrice;
  final String origin;
  final String destination;
  final Map<String, dynamic>? metadata;

  FlightEstimateResponse({
    required this.flights,
    this.minPrice,
    this.maxPrice,
    this.averagePrice,
    required this.origin,
    required this.destination,
    this.metadata,
  });

  factory FlightEstimateResponse.fromJson(Map<String, dynamic> json) {
    return FlightEstimateResponse(
      flights: json['flights'] != null
          ? (json['flights'] as List).map((f) => Flight.fromJson(f)).toList()
          : [],
      minPrice: json['min_price']?.toDouble(),
      maxPrice: json['max_price']?.toDouble(),
      averagePrice: json['average_price']?.toDouble(),
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      metadata: json['metadata'],
    );
  }
}

class FlightRoute {
  final String origin;
  final String destination;
  final String originCity;
  final String destinationCity;
  final double? averagePrice;
  final int? averageDuration;
  final List<String>? popularAirlines;

  FlightRoute({
    required this.origin,
    required this.destination,
    required this.originCity,
    required this.destinationCity,
    this.averagePrice,
    this.averageDuration,
    this.popularAirlines,
  });

  factory FlightRoute.fromJson(Map<String, dynamic> json) {
    return FlightRoute(
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      originCity: json['origin_city'] ?? '',
      destinationCity: json['destination_city'] ?? '',
      averagePrice: json['average_price']?.toDouble(),
      averageDuration: json['average_duration']?.toInt(),
      popularAirlines: json['popular_airlines'] != null
          ? List<String>.from(json['popular_airlines'])
          : null,
    );
  }
}