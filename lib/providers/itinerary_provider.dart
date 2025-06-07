// lib/providers/itinerary_provider.dart
import 'package:flutter/material.dart';
import '../models/itinerary.dart';
import '../services/api_service.dart';

class ItineraryProvider with ChangeNotifier {
  List<Itinerary> _itineraries = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<Itinerary> get itineraries => _itineraries;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Helper method to set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Helper method to clear error
  void _clearError() {
    _error = '';
    notifyListeners();
  }

  // Fetch all itineraries from API
  Future<void> fetchItineraries() async {
    _setLoading(true);
    _clearError();

    try {
      print('=== FETCHING ITINERARIES ===');
      final itineraryData = await ApiService.getItinerary();
      
      print('Raw itinerary data: $itineraryData');
      print('Data type: ${itineraryData.runtimeType}');
      print('Data length: ${itineraryData.length}');

      // Convert to Itinerary objects
      _itineraries = itineraryData.map((data) {
        try {
          print('Converting data: $data');
          return Itinerary.fromJson(data);
        } catch (e) {
          print('Error converting itinerary data: $e');
          print('Problematic data: $data');
          rethrow;
        }
      }).toList();

      print('Converted ${_itineraries.length} itineraries');
      
      // Sort by creation date (newest first)
      _itineraries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
    } catch (e) {
      print('Error fetching itineraries: $e');
      _setError('Gagal memuat rencana perjalanan: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Add new itinerary (quick add from place)
  Future<bool> addToItinerary(Map<String, dynamic> placeData) async {
    try {
      print('=== ADDING TO ITINERARY ===');
      print('Place data: $placeData');
      
      final response = await ApiService.addToItinerary(placeData);
      print('Add response: $response');

      // Refresh the list after adding
      await fetchItineraries();
      
      return true;
    } catch (e) {
      print('Error adding to itinerary: $e');
      _setError('Gagal menambahkan ke rencana perjalanan: ${e.toString()}');
      return false;
    }
  }

  // Save detailed plan
  Future<bool> savePlan(Map<String, dynamic> planData) async {
    try {
      print('=== SAVING PLAN ===');
      print('Plan data: $planData');
      
      final response = await ApiService.savePlan(planData);
      print('Save response: $response');

      // Refresh the list after saving
      await fetchItineraries();
      
      return true;
    } catch (e) {
      print('Error saving plan: $e');
      _setError('Gagal menyimpan rencana perjalanan: ${e.toString()}');
      return false;
    }
  }

  // Update existing itinerary
  Future<bool> updateItinerary(int itineraryId, Map<String, dynamic> updatedData) async {
    try {
      print('=== UPDATING ITINERARY ===');
      print('Itinerary ID: $itineraryId');
      print('Updated data: $updatedData');

      // For now, we'll use the savePlan method with the updated data
      // You might need to create a separate API endpoint for updates
      final response = await ApiService.savePlan(updatedData);
      print('Update response: $response');

      // Refresh the list after updating
      await fetchItineraries();
      
      return true;
    } catch (e) {
      print('Error updating itinerary: $e');
      _setError('Gagal memperbarui rencana perjalanan: ${e.toString()}');
      return false;
    }
  }

  // Delete itinerary
  Future<bool> deleteItinerary(int itineraryId) async {
    try {
      print('=== DELETING ITINERARY ===');
      print('Itinerary ID: $itineraryId');

      await ApiService.deletePlan(itineraryId.toString());
      
      // Remove from local list immediately for better UX
      _itineraries.removeWhere((itinerary) => itinerary.id == itineraryId);
      notifyListeners();
      
      print('Itinerary deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting itinerary: $e');
      _setError('Gagal menghapus rencana perjalanan: ${e.toString()}');
      
      // Refresh the list to restore state if deletion failed
      await fetchItineraries();
      return false;
    }
  }

  // Get specific itinerary by ID
  Itinerary? getItineraryById(int id) {
    try {
      return _itineraries.firstWhere((itinerary) => itinerary.id == id);
    } catch (e) {
      return null;
    }
  }

  // Filter itineraries by place name
  List<Itinerary> filterByPlace(String placeName) {
    if (placeName.isEmpty) return _itineraries;
    
    return _itineraries.where((itinerary) {
      final name = itinerary.place['name']?.toString().toLowerCase() ?? '';
      return name.contains(placeName.toLowerCase());
    }).toList();
  }

  // Filter itineraries by date range
  List<Itinerary> filterByDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return _itineraries;
    
    return _itineraries.where((itinerary) {
      try {
        final itineraryStart = DateTime.parse(itinerary.dateRange['from']);
        final itineraryEnd = DateTime.parse(itinerary.dateRange['to']);
        
        if (startDate != null && itineraryEnd.isBefore(startDate)) {
          return false;
        }
        
        if (endDate != null && itineraryStart.isAfter(endDate)) {
          return false;
        }
        
        return true;
      } catch (e) {
        print('Error parsing dates for itinerary ${itinerary.id}: $e');
        return false;
      }
    }).toList();
  }

  // Get upcoming itineraries
  List<Itinerary> getUpcomingItineraries() {
    final now = DateTime.now();
    
    return _itineraries.where((itinerary) {
      try {
        final startDate = DateTime.parse(itinerary.dateRange['from']);
        return startDate.isAfter(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Get past itineraries
  List<Itinerary> getPastItineraries() {
    final now = DateTime.now();
    
    return _itineraries.where((itinerary) {
      try {
        final endDate = DateTime.parse(itinerary.dateRange['to']);
        return endDate.isBefore(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Get current/ongoing itineraries
  List<Itinerary> getCurrentItineraries() {
    final now = DateTime.now();
    
    return _itineraries.where((itinerary) {
      try {
        final startDate = DateTime.parse(itinerary.dateRange['from']);
        final endDate = DateTime.parse(itinerary.dateRange['to']);
        return now.isAfter(startDate) && now.isBefore(endDate);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Calculate total estimated cost for all itineraries
  double getTotalEstimatedCost() {
    return _itineraries.fold(0.0, (total, itinerary) {
      return total + (itinerary.estimatedCost ?? 0.0);
    });
  }

  // Get statistics
  Map<String, dynamic> getStatistics() {
    final upcoming = getUpcomingItineraries().length;
    final past = getPastItineraries().length;
    final current = getCurrentItineraries().length;
    final total = _itineraries.length;
    final totalCost = getTotalEstimatedCost();

    return {
      'total': total,
      'upcoming': upcoming,
      'current': current,
      'past': past,
      'totalEstimatedCost': totalCost,
    };
  }

  // Clear all data (useful for logout)
  void clearData() {
    _itineraries.clear();
    _error = '';
    _isLoading = false;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await fetchItineraries();
  }
}