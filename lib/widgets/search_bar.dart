import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class SearchBarWidget extends StatefulWidget {
  final Function(double lat, double lng, String query) onSearch;

  const SearchBarWidget({
    Key? key,
    required this.onSearch,
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _useCurrentLocation = false;

  @override
  void dispose() {
    _locationController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (_useCurrentLocation) {
      await _getCurrentLocation();
    } else {
      final location = _locationController.text.trim();
      if (location.isEmpty) {
        setState(() {
          _errorMessage = 'Mohon masukkan nama lokasi atau pilih "Lokasi Saya"';
          _isLoading = false;
        });
        return;
      }
      await _geocodeLocation(location);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Izin lokasi ditolak. Silakan aktifkan izin lokasi di pengaturan aplikasi.';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      widget.onSearch(position.latitude, position.longitude, _queryController.text);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      String errorMsg = 'Tidak dapat mengakses lokasi Anda. ';
      if (e is LocationServiceDisabledException) {
        errorMsg += 'Silakan aktifkan layanan lokasi.';
      } else if (e is PermissionDeniedException) {
        errorMsg += 'Izin lokasi ditolak.';
      } else if (e is TimeoutException) {
        errorMsg += 'Permintaan lokasi timeout. Silakan coba lagi.';
      } else {
        errorMsg += 'Silakan coba lagi atau masukkan nama lokasi.';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  Future<void> _geocodeLocation(String location) async {
    try {
      String searchLocation = location;
      if (!searchLocation.toLowerCase().contains('indonesia') && 
          !RegExp(r'\d{5,}').hasMatch(searchLocation) && 
          searchLocation.split(',').length < 2) {
        searchLocation += ', Indonesia';
      }

      List<Location> locations = await locationFromAddress(searchLocation);
      
      if (locations.isNotEmpty) {
        final loc = locations.first;
        widget.onSearch(loc.latitude, loc.longitude, _queryController.text);
      } else {
        setState(() {
          _errorMessage = 'Lokasi tidak ditemukan. Silakan coba dengan nama lokasi yang lebih spesifik.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mendapatkan koordinat lokasi. Silakan periksa nama lokasi dan coba lagi.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleCurrentLocation() {
    setState(() {
      _useCurrentLocation = !_useCurrentLocation;
      if (_useCurrentLocation) {
        _locationController.text = 'Lokasi Saya';
      } else {
        _locationController.clear();
      }
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue[600]!,
            Colors.blue[800]!,
          ],
        ),
      ),
      child: Column(
        children: [
          // Location input field
          TextField(
            controller: _locationController,
            enabled: !_useCurrentLocation,
            decoration: InputDecoration(
              hintText: 'Cari tujuan wisatamu',
              prefixIcon: const Icon(Icons.location_on),
              suffixIcon: TextButton(
                onPressed: _toggleCurrentLocation,
                child: Text(
                  _useCurrentLocation ? 'Manual' : 'Lokasi Saya',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            onChanged: (value) {
              if (_errorMessage.isNotEmpty) {
                setState(() {
                  _errorMessage = '';
                });
              }
            },
          ),
          const SizedBox(height: 12),
          // Query input field
          TextField(
            controller: _queryController,
            decoration: InputDecoration(
              hintText: 'Apa yang ingin Anda cari? (contoh: tempat wisata, restoran)',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Mencari...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Cari',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          // Error message
          if (_errorMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Tip
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: const Text(
              'Tip: Masukkan nama lokasi spesifik seperti "Bandung, Jawa Barat" untuk hasil terbaik.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}