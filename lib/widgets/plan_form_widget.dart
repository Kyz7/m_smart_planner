import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class PlanFormWidget extends StatefulWidget {
  final Place place;

  const PlanFormWidget({
    Key? key,
    required this.place,
  }) : super(key: key);

  @override
  _PlanFormWidgetState createState() => _PlanFormWidgetState();
}

class _PlanFormWidgetState extends State<PlanFormWidget> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 1));
  int _adults = 1;
  int _children = 0;
  
  bool _includeFlightCost = false;
  bool _showFlightInput = false;
  double _flightCost = 0.0;
  double _manualFlightCost = 0.0;
  
  Map<String, dynamic>? _estimation;
  bool _isCalculating = false;
  bool _isSaving = false;
  bool _saveSuccess = false;
  String _saveError = '';

  final TextEditingController _flightCostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calculateEstimation();
  }

  @override
  void dispose() {
    _flightCostController.dispose();
    super.dispose();
  }

  Future<void> _calculateEstimation() async {
    setState(() {
      _isCalculating = true;
    });

    try {
      final duration = _endDate.difference(_startDate).inDays + 1;
      final pricePerDay = widget.place.price ?? 150000;
      
      double totalCost = pricePerDay * duration * (_adults + _children * 0.5);
      
      final currentFlightCost = _manualFlightCost > 0 ? _manualFlightCost : _flightCost;
      
      if (_includeFlightCost && currentFlightCost > 0) {
        totalCost += currentFlightCost * (_adults + _children * 0.75);
      }
      
      setState(() {
        _estimation = {
          'duration': duration,
          'totalCost': totalCost,
          'flightIncluded': _includeFlightCost,
        };
      });
    } catch (e) {
      print('Error calculating estimation: $e');
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
      _calculateEstimation();
    }
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() {
      _isSaving = true;
      _saveSuccess = false;
      _saveError = '';
    });

    try {
      final planData = {
        'place': {
          'name': widget.place.name,
          'address': widget.place.formattedAddress,
          'location': {
            'lat': widget.place.lat ?? -6.2088,
            'lng': widget.place.lng ?? 106.8456,
          },
          'rating': widget.place.rating,
          'photo': widget.place.imageUrl,
        },
        'dateRange': {
          'from': _startDate.toIso8601String(),
          'to': _endDate.toIso8601String(),
        },
        'estimatedCost': _estimation?['totalCost'] ?? 0,
        'travelers': {
          'adults': _adults,
          'children': _children,
        },
      };

      if (_includeFlightCost && (_flightCost > 0 || _manualFlightCost > 0)) {
        planData['flight'] = {
          'origin': 'Manual Input',
          'destination': widget.place.name,
          'cost': _manualFlightCost > 0 ? _manualFlightCost : _flightCost,
        };
      }

      await ApiService.savePlan(planData);
      
      setState(() {
        _saveSuccess = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rencana perjalanan berhasil disimpan!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Lihat',
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/itinerary'),
          ),
        ),
      );

      // Auto navigate after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushNamed(context, '/itinerary');
        }
      });

    } catch (error) {
      setState(() {
        _saveError = 'Gagal menyimpan rencana perjalanan. Silakan coba lagi.';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rencanakan Kunjungan Anda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            
            // Date Selection
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Tanggal Mulai',
                    _startDate,
                    () => _selectDate(context, true),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    'Tanggal Selesai',
                    _endDate,
                    () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Travelers
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    'Dewasa',
                    _adults,
                    1,
                    10,
                    (value) {
                      setState(() {
                        _adults = value;
                      });
                      _calculateEstimation();
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    'Anak-anak',
                    _children,
                    0,
                    10,
                    (value) {
                      setState(() {
                        _children = value;
                      });
                      _calculateEstimation();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Flight Options
            _buildFlightSection(),
            SizedBox(height: 20),
            
            // Estimation
            if (_estimation != null) _buildEstimationCard(),
            SizedBox(height: 20),
            
            // Success/Error Messages
            if (_saveSuccess) _buildSuccessMessage(),
            if (_saveError.isNotEmpty) _buildErrorMessage(),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Menyimpan...'),
                        ],
                      )
                    : Text(
                        'Simpan ke Itinerary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  _formatDate(date),
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, int value, int min, int max, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: Icon(Icons.remove, size: 18),
                color: Colors.grey[600],
              ),
              Expanded(
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: Icon(Icons.add, size: 18),
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),
        SizedBox(height: 12),
        Text(
          'Opsi Penerbangan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        
        CheckboxListTile(
          title: Text('Masukkan biaya penerbangan'),
          subtitle: Text(
            'Estimasi penerbangan belum tersedia, Anda bisa memasukkan biaya sendiri',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          value: _showFlightInput,
          onChanged: (value) {
            setState(() {
              _showFlightInput = value ?? false;
              if (_showFlightInput) {
                _includeFlightCost = true;
              } else {
                _includeFlightCost = false;
                _manualFlightCost = 0.0;
                _flightCostController.clear();
              }
            });
            _calculateEstimation();
          },
          contentPadding: EdgeInsets.zero,
        ),
        
        if (_showFlightInput) ...[
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biaya Penerbangan per Orang (IDR)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _flightCostController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 1500000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixText: 'Rp ',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _manualFlightCost = double.tryParse(value) ?? 0.0;
                    });
                    _calculateEstimation();
                  },
                ),
                SizedBox(height: 4),
                Text(
                  'Masukkan biaya tiket pesawat pulang-pergi per orang',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEstimationCard() {
    final estimation = _estimation!;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimasi untuk ${estimation['duration']} hari, $_adults dewasa${_children > 0 ? ', $_children anak-anak' : ''}${estimation['flightIncluded'] ? ' (termasuk penerbangan)' : ''}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            _formatCurrency(estimation['totalCost']),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[600],
            ),
          ),
          if (estimation['flightIncluded']) ...[
            SizedBox(height: 4),
            Text(
              '* Termasuk biaya penerbangan untuk ${_adults + _children} orang',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Berhasil! Rencana perjalanan Anda telah disimpan ke daftar itinerary.',
              style: TextStyle(color: Colors.green[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _saveError,
              style: TextStyle(color: Colors.red[800]),
            ),
          ),
        ],
      ),
    );
  }
}