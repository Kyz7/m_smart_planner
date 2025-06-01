import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/itinerary.dart';
import '../services/api_service.dart';

class ItineraryProvider with ChangeNotifier {
  List<TravelPlan> _plans = [];
  bool _isLoading = false;
  String _error = '';

  List<TravelPlan> get plans => _plans;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadPlans() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _plans = await ApiService.getUserPlans();
    } catch (e) {
      _error = 'Failed to load plans: $e';
      _plans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> savePlan(Map<String, dynamic> planData) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final newPlan = await ApiService.savePlan(planData);
      _plans.insert(0, newPlan);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save plan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePlan(String planId) async {
    try {
      await ApiService.deletePlan(planId);
      _plans.removeWhere((plan) => plan.id == planId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete plan: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  double calculateTotalBudget() {
    return _plans.fold(0.0, (sum, plan) => sum + plan.estimatedCost);
  }

  int getTotalDays() {
    return _plans.fold(0, (sum, plan) => sum + (plan.duration?.inDays ?? 0));
  }
}