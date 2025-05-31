import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';
import '../models/weather.dart';
import '../services/api_service.dart';

class PlacesProvider with ChangeNotifier {
  List<Place> _places = [];
  bool _isLoading = false;
  String _error = '';
  Position? _currentPosition;
  String _currentLocationName = '';
  WeatherData? _weather;
  int _searchCount = 0;
  Map<String, dynamic> _pagination = {};

  List<Place> get places => _places;
  bool get isLoading => _isLoading;
  String get error => _error;
  Position? get currentPosition => _currentPosition;
  String get currentLocationName => _currentLocationName;
  WeatherData? get weather => _weather;
  int get searchCount => _searchCount;
  Map<String, dynamic> get pagination => _pagination;

  PlacesProvider() {
    _loadSearchCount();
    _initializeLocation();
  }

  Future<void> _loadSearchCount() async {
    final prefs = await SharedPreferences.getInstance();
    _searchCount = prefs.getInt('guestSearchCount') ?? 0;
    notifyListeners();
  }

  Future<void> _initializeLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _handleLocationError('Location permission denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      await _getLocationName(position.latitude, position.longitude);
      await _fetchWeather(position.latitude, position.longitude);
      await fetchNearbyPlaces(position.latitude, position.longitude);

    } catch (e) {
      _handleLocationError(e.toString());
    }
  }

  Future<void> _getLocationName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentLocationName = '${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
    } catch (e) {
      _currentLocationName = 'Lat: ${lat.toStringAsFixed(2)}, Lng: ${lng.toStringAsFixed(2)}';
    }
    notifyListeners();
  }

  void _handleLocationError(String error) {
    _error = 'Failed to get location: $error. Using default location.';
    _currentPosition = Position(
      latitude: -6.2088,
      longitude: 106.8456,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    _currentLocationName = 'Jakarta, Indonesia';
    _fetchWeather(-6.2088, 106.8456);
    fetchNearbyPlaces(-6.2088, 106.8456);
    notifyListeners();
  }

  Future<void> _fetchWeather(double lat, double lng) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      _weather = await ApiService.getWeather(lat, lng, today);
      notifyListeners();
    } catch (e) {
      print('Error fetching weather: $e');
    }
  }



Future<void> fetchNearbyPlaces(double lat, double lng, {String query = '', int page = 1}) async {
  // Check search limit for guests
 try {
  print('=== DEBUG: Memulai fetch places ===');
  print('Lat: $lat, Lng: $lng, Query: "$query", Page: $page');
  
  final result = await ApiService.getPlaces(
    lat: lat,
    lng: lng,
    query: query,
    page: page,
  );

  print('=== DEBUG: Response dari API ===');
  print('Result type: ${result.runtimeType}');
  print('Result keys: ${result.keys.toList()}');
  
  // Debug places data
  final placesData = result['places'];
  print('Places data type: ${placesData.runtimeType}');
  print('Places data: $placesData');
  
  if (placesData is List) {
    print('Places adalah List dengan ${placesData.length} items');
    if (placesData.isNotEmpty) {
      print('Item pertama: ${placesData[0]}');
    }
  } else {
    print('ERROR: Places bukan List!');
  }

  _places = result['places'];
  _pagination = result['pagination'] ?? {};

  print('=== DEBUG: Setelah assignment ===');
  print('_places length: ${_places?.length ?? "null"}');
  print('_places content: $_places');

  if (_places == null || _places.isEmpty) {
    print('Places kosong atau null, set error message');
    _error = 'No tourist destinations found in this location.';
  } else {
    print('Berhasil load ${_places.length} places');
    _error = ''; // Clear error jika ada data
  }

  // Update search count for guests
  if (page == 1) {
    _searchCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('guestSearchCount', _searchCount);
    print('Search count updated: $_searchCount');
  }

} catch (e) {
  print('=== DEBUG: ERROR ===');
  print('Error: $e');
  print('Error type: ${e.runtimeType}');
  
  _error = 'Failed to fetch places: $e';
  _places = [];
} finally {
  _isLoading = false;
  print('=== DEBUG: Finally ===');
  print('isLoading: $_isLoading');
  print('places count: ${_places?.length ?? 0}');
  print('error: $_error');
  notifyListeners();
}
}

  Future<void> searchPlaces(double lat, double lng, String query) async {
    _currentPosition = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    
    await _getLocationName(lat, lng);
    await _fetchWeather(lat, lng);
    await fetchNearbyPlaces(lat, lng, query: query);
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void resetSearchCount() {
    _searchCount = 0;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('guestSearchCount');
    });
    notifyListeners();
  }
}