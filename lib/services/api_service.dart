import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';
import '../models/weather.dart';

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
      Uri.parse('$baseUrl/api/auth/login'),
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
      Uri.parse('$baseUrl/api/auth/register'),
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
      Uri.parse('$baseUrl/api/estimate'),
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

  // ✅ NEW: Add to Itinerary method - Quick add without detailed planning
  static Future<Map<String, dynamic>> addToItinerary(Map<String, dynamic> placeData) async {
    print('=== ADD TO ITINERARY DEBUG ===');
    print('Place data being sent: ${jsonEncode(placeData)}');
    
    // Create a simplified plan with default values for quick add
    final quickPlanData = {
      'place': placeData,
      'dateRange': {
        'from': DateTime.now().add(Duration(days: 1)).toIso8601String(),
        'to': DateTime.now().add(Duration(days: 2)).toIso8601String(),
      },
      'estimatedCost': placeData['price'] ?? 150000,
      'travelers': {
        'adults': 1,
        'children': 0,
      },
      'duration': 1,
      'flight': {
        'included': false,
        'cost': 0,
      },
      'metadata': {
        'quickAdd': true,
        'createdAt': DateTime.now().toIso8601String(),
        'source': 'mobile_app_quick_add',
      },
    };
    
    print('Quick plan data: ${jsonEncode(quickPlanData)}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/plans'),
      headers: await _getHeaders(),
      body: jsonEncode(quickPlanData),
    );

    print('Add to itinerary response status: ${response.statusCode}');
    print('Add to itinerary response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = _getErrorMessage(response.statusCode, response.body);
      throw Exception(errorMessage);
    }
  }

  // ✅ NEW: Save detailed plan method
  static Future<Map<String, dynamic>> savePlan(Map<String, dynamic> planData) async {
    print('=== SAVE PLAN DEBUG ===');
    print('Plan data being sent: ${jsonEncode(planData)}');
    
    // Validate plan data before sending
    if (!_validatePlanData(planData)) {
      throw Exception('Invalid plan data');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/plans'),
      headers: await _getHeaders(),
      body: jsonEncode(planData),
    );

    print('Save plan response status: ${response.statusCode}');
    print('Save plan response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return _extractPlanFromResponse(responseData);
    } else {
      final errorMessage = _getErrorMessage(response.statusCode, response.body);
      throw Exception(errorMessage);
    }
  }

  // ✅ NEW: Get user's itinerary/plans
  static Future<List<Map<String, dynamic>>> getItinerary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/plans'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('plans')) {
        return List<Map<String, dynamic>>.from(data['plans']);
      } else if (data is Map && data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } else {
      throw Exception('Failed to fetch itinerary: ${response.body}');
    }
  }

  // ✅ Helper method to extract plan from different response structures
  static Map<String, dynamic> _extractPlanFromResponse(Map<String, dynamic> responseData) {
    // Try different possible response structures
    if (responseData.containsKey('plan')) {
      return responseData['plan'];
    } else if (responseData.containsKey('data')) {
      if (responseData['data'] is Map) {
        return responseData['data'];
      } else if (responseData['data'] is List && (responseData['data'] as List).isNotEmpty) {
        return (responseData['data'] as List).first;
      }
    } else if (responseData.containsKey('result')) {
      return responseData['result'];
    } else if (responseData.containsKey('travelPlan')) {
      return responseData['travelPlan'];
    } else {
      // If response is directly the plan object
      return responseData;
    }
    
    throw Exception('Unable to extract plan data from response');
  }

  // ✅ Helper method to generate appropriate error messages
  static String _getErrorMessage(int statusCode, String responseBody) {
    switch (statusCode) {
      case 400:
        return 'Bad request: Invalid data sent to server';
      case 401:
        return 'Unauthorized: Please login again';
      case 403:
        return 'Forbidden: You don\'t have permission to perform this action';
      case 404:
        return 'Not found: The requested resource was not found';
      case 422:
        return 'Validation error: Please check your input data';
      case 500:
        return 'Server error: Please try again later';
      default:
        return 'Failed to save plan (${statusCode}): $responseBody';
    }
  }

  // ✅ Enhanced validation with better error messages
  static bool _validatePlanData(Map<String, dynamic> planData) {
    print('=== VALIDATING PLAN DATA ===');
    
    // Check required top-level fields
    final requiredFields = ['place', 'dateRange', 'estimatedCost'];
    
    for (String field in requiredFields) {
      if (!planData.containsKey(field) || planData[field] == null) {
        print('❌ Missing required field: $field');
        return false;
      }
    }
    
    // Validate place structure
    final place = planData['place'];
    if (place is! Map) {
      print('❌ Place field is not a Map');
      return false;
    }
    
    final requiredPlaceFields = ['name'];
    for (String field in requiredPlaceFields) {
      if (!place.containsKey(field) || place[field] == null) {
        print('❌ Missing required place field: $field');
        return false;
      }
    }
    
    // Validate place name
    if (place['name'].toString().trim().isEmpty) {
      print('❌ Place name is empty');
      return false;
    }
    
    // Validate dateRange structure
    final dateRange = planData['dateRange'];
    if (dateRange is! Map || 
        !dateRange.containsKey('from') || 
        !dateRange.containsKey('to')) {
      print('❌ Invalid dateRange structure');
      return false;
    }
    
    // Validate date formats (basic check)
    try {
      DateTime.parse(dateRange['from'].toString());
      DateTime.parse(dateRange['to'].toString());
    } catch (e) {
      print('❌ Invalid date format in dateRange');
      return false;
    }
    
    // Validate estimatedCost
    final estimatedCost = planData['estimatedCost'];
    if (estimatedCost is! num || estimatedCost < 0) {
      print('❌ Invalid estimatedCost value');
      return false;
    }
    
    print('✅ Plan data validation passed');
    return true;
  }

  static Future<void> deletePlan(String planId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/plans/$planId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
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