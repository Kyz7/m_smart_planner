import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';
import '../models/weather.dart';
import '../models/itinerary.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.6:3000'; // Replace with your API URL
  
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Authentication
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(),
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  // Places
  static Future<Map<String, dynamic>> getPlaces({
  required double lat,
  required double lng,
  String query = '',
  int page = 1,
  int limit = 9,
}) async {
  final uri = Uri.parse('$baseUrl/api/places').replace(queryParameters: {
    'lat': lat.toString(),
    'lon': lng.toString(),
    'query': query,
    'page': page.toString(),
    'limit': limit.toString(),
  });

  print('=== API DEBUG ===');
  print('Request URL: $uri');

  final response = await http.get(uri, headers: await _getHeaders());

  print('Response status: ${response.statusCode}');
  print('Response body length: ${response.body.length}');
  print('Response body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('JSON decode success');
    print('Response data keys: ${data.keys.toList()}');
    
    // Check places data specifically
    if (data.containsKey('places')) {
      final places = data['places'];
      print('Places found in response');
      print('Places type: ${places.runtimeType}');
      print('Places length: ${places is List ? places.length : 'not a list'}');
    } else {
      print('ERROR: No "places" key in response!');
    }

    return {
      'places': (data['places'] as List).map((p) => Place.fromJson(p)).toList(),
      'pagination': data['pagination'],
    };
  } else {
    print('API Error: ${response.body}');
    throw Exception('Failed to fetch places: ${response.body}');
  }
}

  // Weather
  static Future<WeatherData> getWeather(double lat, double lng, String date) async {
    final uri = Uri.parse('$baseUrl/api/weather').replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'date': date,
    });

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch weather: ${response.body}');
    }
  }

  // Cost Estimation
  static Future<Map<String, dynamic>> getEstimation(Map<String, dynamic> estimationData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/estimation'),
      headers: await _getHeaders(),
      body: jsonEncode(estimationData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get estimation: ${response.body}');
    }
  }

  // Flight Estimation
  static Future<Map<String, dynamic>> getFlightEstimate(String fromCode, String toCode) async {
    final uri = Uri.parse('$baseUrl/api/flights').replace(queryParameters: {
      'from': fromCode,
      'to': toCode,
    });

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch flight estimate: ${response.body}');
    }
  }

  // Itinerary
  static Future<List<TravelPlan>> getUserPlans() async {
    final response = await http.get(
      Uri.parse('$baseUrl/plans'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['plans'] as List).map((p) => TravelPlan.fromJson(p)).toList();
    } else {
      throw Exception('Failed to fetch plans: ${response.body}');
    }
  }

  static Future<TravelPlan> savePlan(Map<String, dynamic> planData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/plans'),
      headers: await _getHeaders(),
      body: jsonEncode(planData),
    );

    if (response.statusCode == 201) {
      return TravelPlan.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to save plan: ${response.body}');
    }
  }

  static Future<void> deletePlan(String planId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/plans/$planId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete plan: ${response.body}');
    }
  }

  // Geocoding
  static Future<Map<String, dynamic>> geocode(String address) async {
    final uri = Uri.parse('$baseUrl/api/geocode').replace(queryParameters: {
      'address': address,
    });

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to geocode: ${response.body}');
    }
  }
}