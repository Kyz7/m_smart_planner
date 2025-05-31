import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/place.dart';
import '../services/flight_service.dart';
import '../utils/format_currency.dart';
import 'dart:math';

class FlightEstimationWidget extends StatefulWidget {
  final LatLng? userLocation;
  final LatLng? destinationLocation;
  final ValueChanged<FlightEstimationData?>? onFlightDataChanged;

  const FlightEstimationWidget({
    Key? key,
    this.userLocation,
    this.destinationLocation,
    this.onFlightDataChanged,
  }) : super(key: key);

  @override
  State<FlightEstimationWidget> createState() => _FlightEstimationWidgetState();
}

class _FlightEstimationWidgetState extends State<FlightEstimationWidget> {
  FlightEstimationData? _flightData;
  bool _loading = false;
  String _error = '';
  bool _showFlightOption = false;

  @override
  void initState() {
    super.initState();
    _checkFlightNeeded();
  }

  @override
  void didUpdateWidget(FlightEstimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userLocation != widget.userLocation ||
        oldWidget.destinationLocation != widget.destinationLocation) {
      _checkFlightNeeded();
    }
  }

  // Haversine formula to calculate distance between two coordinates
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371; // Earth radius in kilometers
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Find nearest airport based on location
  Airport? _findNearestAirport(double lat, double lng) {
    final airports = _getIndonesianAirports();
    
    Airport? nearestAirport;
    double minDistance = double.infinity;

    for (final airport in airports) {
      final distance = _calculateDistance(lat, lng, airport.lat, airport.lng);
      if (distance < minDistance) {
        minDistance = distance;
        nearestAirport = airport;
      }
    }

    return nearestAirport;
  }

  List<Airport> _getIndonesianAirports() {
    return [
      // Jabodetabek & Banten
      Airport(code: 'CGK', name: 'Soekarno-Hatta International Airport', city: 'Jakarta', lat: -6.1256, lng: 106.6559),
      Airport(code: 'HLP', name: 'Halim Perdanakusuma Airport', city: 'Jakarta', lat: -6.2665, lng: 106.8909),
      
      // Jawa Barat
      Airport(code: 'BDO', name: 'Husein Sastranegara Airport', city: 'Bandung', lat: -6.9006, lng: 107.5763),
      
      // Jawa Tengah & Yogyakarta
      Airport(code: 'JOG', name: 'Yogyakarta International Airport', city: 'Yogyakarta', lat: -7.9006, lng: 110.0567),
      Airport(code: 'SOC', name: 'Adisumarmo Airport', city: 'Solo', lat: -7.5162, lng: 110.7569),
      Airport(code: 'SRG', name: 'Ahmad Yani Airport', city: 'Semarang', lat: -6.9714, lng: 110.3742),
      
      // Jawa Timur
      Airport(code: 'MLG', name: 'Abdul Rachman Saleh Airport', city: 'Malang', lat: -7.9265, lng: 112.7145),
      Airport(code: 'JBB', name: 'Juanda International Airport', city: 'Surabaya', lat: -7.3797, lng: 112.7869),
      
      // Bali
      Airport(code: 'DPS', name: 'Ngurah Rai International Airport', city: 'Denpasar', lat: -8.7462, lng: 115.1669),
      
      // Sumatra
      Airport(code: 'KNO', name: 'Kualanamu International Airport', city: 'Medan', lat: 3.6422, lng: 98.8853),
      Airport(code: 'PKU', name: 'Sultan Syarif Kasim II Airport', city: 'Pekanbaru', lat: 0.4609, lng: 101.4450),
      Airport(code: 'PDG', name: 'Minangkabau International Airport', city: 'Padang', lat: -0.7868, lng: 100.2809),
      Airport(code: 'PLM', name: 'Sultan Mahmud Badaruddin II Airport', city: 'Palembang', lat: -2.8976, lng: 104.6997),
      Airport(code: 'BKS', name: 'Fatmawati Soekarno Airport', city: 'Bengkulu', lat: -3.8637, lng: 102.3394),
      
      // Kalimantan
      Airport(code: 'BPN', name: 'Sultan Aji Muhammad Sulaiman Airport', city: 'Balikpapan', lat: -1.2683, lng: 116.8945),
      Airport(code: 'BDJ', name: 'Syamsudin Noor Airport', city: 'Banjarmasin', lat: -3.4424, lng: 114.7625),
      Airport(code: 'PNK', name: 'Supadio Airport', city: 'Pontianak', lat: -0.1509, lng: 109.4038),
      
      // Sulawesi
      Airport(code: 'UPG', name: 'Sultan Hasanuddin Airport', city: 'Makassar', lat: -5.0617, lng: 119.5540),
      Airport(code: 'MDC', name: 'Sam Ratulangi Airport', city: 'Manado', lat: 1.5493, lng: 124.9269),
      
      // Papua
      Airport(code: 'DJJ', name: 'Sentani Airport', city: 'Jayapura', lat: -2.5769, lng: 140.5159),
    ];
  }

  Future<void> _checkFlightNeeded() async {
    if (widget.userLocation == null || widget.destinationLocation == null) {
      debugPrint('Missing location data');
      return;
    }

    try {
      final distance = _calculateDistance(
        widget.userLocation!.latitude,
        widget.userLocation!.longitude,
        widget.destinationLocation!.latitude,
        widget.destinationLocation!.longitude,
      );

      debugPrint('Distance calculated: ${distance.toStringAsFixed(2)} km');

      // Only show flight option if distance > 500km (inter-island or very long distance)
      if (distance > 500) {
        final originAirport = _findNearestAirport(
          widget.userLocation!.latitude,
          widget.userLocation!.longitude,
        );
        final destAirport = _findNearestAirport(
          widget.destinationLocation!.latitude,
          widget.destinationLocation!.longitude,
        );

        debugPrint('Nearest airports: ${originAirport?.code} -> ${destAirport?.code}');

        // Ensure origin and destination airports are different
        if (originAirport != null && destAirport != null && originAirport.code != destAirport.code) {
          setState(() {
            _showFlightOption = true;
          });
          await _fetchFlightEstimation(originAirport, destAirport);
        } else {
          debugPrint('Same airport or missing airport data, hiding flight option');
          setState(() {
            _showFlightOption = false;
          });
        }
      } else {
        debugPrint('Distance too short for flight, hiding flight option');
        setState(() {
          _showFlightOption = false;
          _flightData = null;
        });
      }
    } catch (err) {
      debugPrint('Error checking flight needed: $err');
      setState(() {
        _error = 'Failed to check flight options';
      });
    }
  }

  Future<void> _fetchFlightEstimation(Airport originAirport, Airport destAirport) async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      debugPrint('Fetching flight data from ${originAirport.code} to ${destAirport.code}');

      // Calculate estimated cost based on distance and route type
      const double baseCost = 800000; // Base cost 800k
      final distance = _calculateDistance(originAirport.lat, originAirport.lng, destAirport.lat, destAirport.lng);
      const double costPerKm = 300; // 300 per km
      final double estimatedCost = baseCost + (distance * costPerKm);

      List<Flight> flights; // This will now use the Flight from FlightService
      
      try {
        // Try to get real flight data from API
        flights = await FlightService.getFlightEstimate(originAirport.code, destAirport.code);
        
        if (flights.isEmpty) {
          throw Exception('No flights found');
        }
      } catch (err) {
        debugPrint('Error fetching flight data: $err, using mock data');
        
        // Fallback to mock data if API fails  
        flights = _generateMockFlights(originAirport.code, destAirport.code);
        setState(() {
          _error = 'Menggunakan data estimasi penerbangan';
        });
      }

      final flightEstimationData = FlightEstimationData(
        flights: flights,
        estimatedCost: estimatedCost.round(),
        origin: originAirport.code,
        destination: destAirport.code,
        originAirport: originAirport,
        destinationAirport: destAirport,
        distance: distance.round(),
      );

      setState(() {
        _flightData = flightEstimationData;
      });

      // Notify parent widget about flight data change
      if (widget.onFlightDataChanged != null) {
        widget.onFlightDataChanged!(flightEstimationData);
      }

      debugPrint('Flight data set successfully: ${flightEstimationData.flights.length} flights');
    } catch (err) {
      debugPrint('Error fetching flight data: $err');
      setState(() {
        _error = 'Gagal mengambil data penerbangan';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Updated to return the proper Flight model from FlightService
  List<Flight> _generateMockFlights(String fromCode, String toCode) {
    final random = Random();
    final now = DateTime.now();
    
    return [
      Flight(
        flightNumber: 'GA-${100 + random.nextInt(900)}',
        airline: 'Garuda Indonesia',
        departure: FlightTime(
          scheduled: now.add(Duration(hours: 24 + random.nextInt(12))),
          iata: fromCode,
        ),
        arrival: FlightTime(
          scheduled: now.add(Duration(hours: 26 + random.nextInt(12))),
          iata: toCode,
        ),
        status: 'scheduled',
        price: 800000 + random.nextInt(500000).toDouble(), // Add price for mock data
        duration: 120 + random.nextInt(180), // Add duration in minutes
      ),
      Flight(
        flightNumber: 'JT-${100 + random.nextInt(900)}',
        airline: 'Lion Air',
        departure: FlightTime(
          scheduled: now.add(Duration(hours: 30 + random.nextInt(12))),
          iata: fromCode,
        ),
        arrival: FlightTime(
          scheduled: now.add(Duration(hours: 32 + random.nextInt(12))),
          iata: toCode,
        ),
        status: 'scheduled',
        price: 700000 + random.nextInt(400000).toDouble(),
        duration: 130 + random.nextInt(170),
      ),
      Flight(
        flightNumber: 'ID-${100 + random.nextInt(900)}',
        airline: 'Batik Air',
        departure: FlightTime(
          scheduled: now.add(Duration(hours: 36 + random.nextInt(12))),
          iata: fromCode,
        ),
        arrival: FlightTime(
          scheduled: now.add(Duration(hours: 38 + random.nextInt(12))),
          iata: toCode,
        ),
        status: 'scheduled',
        price: 750000 + random.nextInt(450000).toDouble(),
        duration: 115 + random.nextInt(185),
      ),
    ];
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'scheduled':
        return 'Terjadwal';
      case 'cancelled':
        return 'Dibatalkan';
      case 'delayed':
        return 'Tertunda';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'scheduled':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'delayed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render if flight option is not needed
    if (!_showFlightOption) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estimasi Penerbangan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Loading indicator
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Mencari penerbangan...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

            // Error message
            if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error,
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // Flight data
            if (_flightData != null) ...[
              // Header with route info and estimated cost
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_flightData!.originAirport?.city} → ${_flightData!.destinationAirport?.city}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_flightData!.originAirport?.name} (${_flightData!.origin})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${_flightData!.destinationAirport?.name} (${_flightData!.destination})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Jarak: ${_flightData!.distance} km',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Estimasi biaya pulang-pergi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(_flightData!.estimatedCost),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              'per orang',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),

              // Flight table
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text('Maskapai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Keberangkatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Kedatangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                    ),
                    // Flight rows
                    ...(_flightData!.flights.take(5).map((flight) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Airline info
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.flight,
                                        size: 14,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        flight.airline,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  flight.flightNumber,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Departure
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(flight.departure.scheduled),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy').format(flight.departure.scheduled),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arrival
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(flight.arrival.scheduled),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy').format(flight.arrival.scheduled),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(flight.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(flight.status),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getStatusColor(flight.status),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Footer with disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catatan Penting:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...([
                            'Harga estimasi berdasarkan data historis dan dapat berubah sewaktu-waktu',
                            'Jadwal penerbangan dapat berubah tanpa pemberitahuan sebelumnya',
                            'Silakan konfirmasi langsung dengan maskapai untuk booking',
                            'Estimasi sudah termasuk biaya pulang-pergi untuk 1 orang',
                          ].map((text) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Supporting classes and models
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}

class Airport {
  final String code;
  final String name;
  final String city;
  final double lat;
  final double lng;

  Airport({
    required this.code,
    required this.name,
    required this.city,
    required this.lat,
    required this.lng,
  });
}

class FlightEstimationData {
  final List<Flight> flights; // Now uses Flight from FlightService
  final int estimatedCost;
  final String origin;
  final String destination;
  final Airport? originAirport;
  final Airport? destinationAirport;
  final int distance;

  FlightEstimationData({
    required this.flights,
    required this.estimatedCost,
    required this.origin,
    required this.destination,
    this.originAirport,
    this.destinationAirport,
    required this.distance,
  });
}