import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/place.dart';
import '../utils/format_currency.dart';

class PlanFormWidget extends StatefulWidget {
  final Place place;
  final VoidCallback? onSaved;

  const PlanFormWidget({
    Key? key,
    required this.place,
    this.onSaved,
  }) : super(key: key);

  @override
  State<PlanFormWidget> createState() => _PlanFormWidgetState();
}

class _PlanFormWidgetState extends State<PlanFormWidget> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime? _startDate;
  DateTime? _endDate;
  int _adults = 1;
  int _children = 0;
  
  EstimationResult? _estimation;
  bool _loading = false;
  bool _saveLoading = false;
  bool _saveSuccess = false;
  String _saveError = '';
  
  double _flightCost = 0;
  bool _includeFlightCost = false;
  Map<String, String>? _nearestAirports;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _loadFlightEstimation();
  }

  void _initializeDates() {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    
    setState(() {
      _startDate = today;
      _endDate = tomorrow;
    });
  }

  void _loadFlightEstimation() {
    // Load flight estimation from shared preferences or local storage
    // This would typically come from your flight estimation service
    // For now, we'll simulate it
    // You can implement SharedPreferences to store and retrieve flight data
  }

  Future<void> _calculateEstimation() async {
    if (_startDate == null || _endDate == null) return;
    
    setState(() {
      _loading = true;
    });
    
    try {
      final duration = _endDate!.difference(_startDate!).inDays + 1;
      final pricePerDay = widget.place.price ?? 150000;
      
      double totalCost = pricePerDay * duration * (_adults + _children * 0.5);
      
      if (_includeFlightCost && _flightCost > 0) {
        totalCost += _flightCost * (_adults + _children * 0.75);
      }
      
      try {
        // Create estimation request data
        final estimationRequest = {
          'price_per_day': pricePerDay,
          'start_date': _startDate!.toIso8601String(),
          'end_date': _endDate!.toIso8601String(),
          'flight_cost': _includeFlightCost ? _flightCost : 0,
          'adults': _adults,
          'children': _children,
        };
        
        final serverEstimation = await ApiService.getEstimation(estimationRequest);
        
        setState(() {
          _estimation = EstimationResult(
            duration: duration,
            totalCost: serverEstimation['total_cost']?.toDouble() ?? totalCost,
            flightIncluded: _includeFlightCost,
          );
        });
      } catch (error) {
        // Fallback to local calculation
        setState(() {
          _estimation = EstimationResult(
            duration: duration,
            totalCost: totalCost,
            flightIncluded: _includeFlightCost,
          );
        });
      }
    } catch (error) {
      debugPrint('Error calculating estimation: $error');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if user is logged in (you'll need to implement auth check)
    // if (!AuthService.isLoggedIn) {
    //   Navigator.pushNamed(context, '/login');
    //   return;
    // }
    
    setState(() {
      _saveLoading = true;
      _saveSuccess = false;
      _saveError = '';
    });
    
    try {
      final planData = {
        'place': {
          'name': widget.place.name,
          'address': widget.place.address ?? '',
          'location': {
            'lat': widget.place.lat ?? -6.2088,
            'lng': widget.place.lng ?? 106.8456,
          },
          'rating': widget.place.rating,
          'photo': widget.place.photo ?? 'https://via.placeholder.com/800x400?text=No+Image',
        },
        'date_range': {
          'from': _startDate!.toIso8601String(),
          'to': _endDate!.toIso8601String(),
        },
        'estimated_cost': _estimation?.totalCost ?? 0,
        'travelers': {
          'adults': _adults,
          'children': _children,
        },
        'flight': _includeFlightCost && _nearestAirports != null
            ? {
                'origin': _nearestAirports!['origin']!,
                'destination': _nearestAirports!['destination']!,
                'cost': _flightCost,
              }
            : null,
      };
      
      await ApiService.savePlan(planData);
      
      setState(() {
        _saveSuccess = true;
      });
      
      // Navigate back or to itinerary after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (widget.onSaved != null) {
          widget.onSaved!();
        } else {
          Navigator.pushReplacementNamed(context, '/itinerary');
        }
      });
      
    } catch (error) {
      setState(() {
        _saveError = 'Gagal menyimpan rencana perjalanan. Silakan coba lagi.';
      });
    } finally {
      setState(() {
        _saveLoading = false;
      });
    }
  }

  Widget _buildDatePicker({
  required String label,
  required DateTime? selectedDate,
  required ValueChanged<DateTime> onDateSelected,
}) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              onDateSelected(date);
              _calculateEstimation();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(  // Add this Expanded widget to prevent overflow
                  child: Text(
                    selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(selectedDate)
                        : 'Pilih tanggal',
                    style: TextStyle(
                      color: selectedDate != null ? Colors.black87 : Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,  // Add this to handle long text gracefully
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildNumberInput({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int min = 0,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Wajib diisi';
              }
              final number = int.tryParse(value);
              if (number == null || number < min) {
                return 'Minimal $min';
              }
              return null;
            },
            onChanged: (value) {
              final number = int.tryParse(value);
              if (number != null && number >= min) {
                onChanged(number);
                _calculateEstimation();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rencanakan Kunjungan Anda',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Date inputs
              Row(
                children: [
                  _buildDatePicker(
                    label: 'Tanggal Mulai',
                    selectedDate: _startDate,
                    onDateSelected: (date) {
                      setState(() {
                        _startDate = date;
                        // Ensure end date is after start date
                        if (_endDate != null && _endDate!.isBefore(date)) {
                          _endDate = date.add(const Duration(days: 1));
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildDatePicker(
                    label: 'Tanggal Selesai',
                    selectedDate: _endDate,
                    onDateSelected: (date) {
                      setState(() {
                        _endDate = date;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Traveler inputs
              Row(
                children: [
                  _buildNumberInput(
                    label: 'Dewasa',
                    value: _adults,
                    min: 1,
                    onChanged: (value) {
                      setState(() {
                        _adults = value;
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildNumberInput(
                    label: 'Anak-anak',
                    value: _children,
                    onChanged: (value) {
                      setState(() {
                        _children = value;
                      });
                    },
                  ),
                ],
              ),
              
              // Flight option
              if (_flightCost > 0 && _nearestAirports != null) ...[
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text(
                    'Sertakan biaya penerbangan (${_nearestAirports!['origin']} - ${_nearestAirports!['destination']})',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    '${CurrencyFormatter.format(_flightCost)} per orang (pulang-pergi)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  value: _includeFlightCost,
                  onChanged: (value) {
                    setState(() {
                      _includeFlightCost = value ?? false;
                    });
                    _calculateEstimation();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              
              // Estimation display
              if (_estimation != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimasi untuk ${_estimation!.duration} hari, $_adults dewasa${_children > 0 ? ', $_children anak-anak' : ''}${_estimation!.flightIncluded ? ' (termasuk penerbangan)' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(_estimation!.totalCost),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Success message
              if (_saveSuccess) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Berhasil! Rencana perjalanan Anda telah disimpan ke daftar itinerary.',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Error message
              if (_saveError.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _saveError,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_loading || _saveLoading) ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: _loading || _saveLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_saveLoading ? 'Menyimpan...' : 'Menghitung...'),
                          ],
                        )
                      : const Text(
                          'Simpan ke Itinerary',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Supporting data classes
class EstimationResult {
  final int duration;
  final double totalCost;
  final bool flightIncluded;

  EstimationResult({
    required this.duration,
    required this.totalCost,
    required this.flightIncluded,
  });
}