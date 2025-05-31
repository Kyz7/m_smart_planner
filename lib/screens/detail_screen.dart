import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';
import '../models/weather.dart';
import '../providers/auth_provider.dart';
import '../providers/itinerary_provider.dart';
import '../utils/format_currency.dart';
import '../widgets/weather_widget.dart';
import '../widgets/plan_form_widget.dart';
import '../widgets/flight_estimation_widget.dart';
import '../widgets/map_widget.dart';

// Model untuk Review
class Review {
  final String user;
  final int rating;
  final String comment;

  Review({
    required this.user,
    required this.rating,
    required this.comment,
  });
}

class DetailScreen extends StatefulWidget {
  final Place? place;
  final String? placeId;

  const DetailScreen({
    Key? key,
    this.place,
    this.placeId,
  }) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Place? _place;
  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _weather;
  int _viewCount = 0;
  Position? _userLocation;
  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _getUserLocation();
    
    if (widget.place != null) {
      setState(() {
        _place = widget.place;
        _loading = false;
      });
      await _fetchWeather();
    } else if (widget.placeId != null) {
      await _fetchPlaceDetails();
    }

    // Handle guest user view count
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      await _handleGuestViewCount();
    }
  }

  Future<void> _handleGuestViewCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt('guestViewCount') ?? 0;
    final newCount = currentCount + 1;
    
    await prefs.setInt('guestViewCount', newCount);
    
    setState(() {
      _viewCount = newCount;
    });

    if (newCount > 2) {
      _showLoginRequired();
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = position;
      });
    } catch (e) {
      print('Error getting user location: $e');
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _userLocation = Position(
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
    });
  }

  Future<void> _fetchPlaceDetails() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // Mock reviews data
      final mockReviews = [
        Review(
          user: 'John Doe', 
          rating: 5, 
          comment: 'Tempat yang sangat indah! Pemandangannya luar biasa dan suasananya sangat menenangkan.'
        ),
        Review(
          user: 'Jane Smith', 
          rating: 4, 
          comment: 'Pemandangan bagus, tapi agak ramai saat weekend. Sebaiknya datang di hari kerja.'
        ),
        Review(
          user: 'Ahmad Rahman', 
          rating: 5, 
          comment: 'Sangat recommended! Tempatnya bersih dan fasilitas lengkap.'
        ),
      ];

      // Mock place data for demonstration
      final dummyPlace = Place(
        placeId: widget.placeId ?? '',
        name: 'Tempat Wisata ${widget.placeId}',
        address: 'Jl. Contoh No. 123, Kota Wisata',
        lat: -6.2088,
        lng: 106.8456,
        rating: 4.5,
        price: 150000,
        photo: 'https://via.placeholder.com/800x400?text=Tempat+Wisata',
      );

      setState(() {
        _place = dummyPlace;
        _reviews = mockReviews;
        _loading = false;
      });

      await _fetchWeather();
    } catch (e) {
      setState(() {
        _error = 'Gagal mendapatkan detail tempat wisata. Silakan coba lagi.';
        _loading = false;
      });
    }
  }

  Future<void> _fetchWeather() async {
    if (_place == null) return;

    try {
      // Mock weather data - replace with actual API call
      final mockWeatherData = {
        'hourly': {
          'temperature_2m': List.generate(24, (i) => 25 + (i % 10) * 0.5 + (i > 12 ? -2 : 2)),
          'weathercode': List.generate(24, (i) => i % 3),
        }
      };

      setState(() {
        _weather = mockWeatherData;
      });
    } catch (e) {
      print('Error fetching weather: $e');
    }
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber),
              SizedBox(width: 8),
              Text('Login Diperlukan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anda telah mencapai batas melihat detail tempat sebagai tamu.'),
              SizedBox(height: 8),
              Text(
                'Login untuk melihat detail tempat lainnya tanpa batas.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text('Nanti'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: Text('Login'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sharePlace() async {
    if (_place == null) return;

    try {
      final description = 'Tempat wisata yang indah dengan pemandangan alam yang menakjubkan. Dikelilingi oleh keindahan alam yang masih asri dan udara yang sejuk, tempat ini menjadi destinasi favorit para wisatawan yang ingin melepas penat dari kesibukan kota.';
      
      await Share.share(
        'Lihat detail tempat wisata ${_place!.name}\n\n$description',
        subject: _place!.name,
      );
    } catch (e) {
      print('Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan tempat wisata')),
        );
      }
    }
  }

  Future<void> _openMap() async {
    if (_place == null) return;

    final url = 'https://www.google.com/maps/search/?api=1&query=${_place!.lat},${_place!.lng}';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error opening map: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka peta')),
        );
      }
    }
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF2563EB),
                child: Text(
                  review.user.isNotEmpty ? review.user[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.user,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat detail tempat wisata...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty || _place == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'Oops!',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _error.isNotEmpty ? _error : 'Tempat wisata tidak ditemukan',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = '';
                    });
                    _initializeScreen();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final description = 'Tempat wisata yang indah dengan pemandangan alam yang menakjubkan. Dikelilingi oleh keindahan alam yang masih asri dan udara yang sejuk, tempat ini menjadi destinasi favorit para wisatawan yang ingin melepas penat dari kesibukan kota.';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Color(0xFF2563EB),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _place!.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _place!.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade300,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: _sharePlace,
                icon: Icon(Icons.share),
                tooltip: 'Bagikan',
              ),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Place info header
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.yellow.shade400,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.grey.shade800),
                                  SizedBox(width: 4),
                                  Text(
                                    _place!.rating?.toString() ?? '0.0',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _place!.address ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mulai dari',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(_place!.price ?? 0),
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _openMap,
                              icon: Icon(Icons.map, size: 18),
                              label: Text('Lihat di Map'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 24),
                        
                        Text(
                          'Tentang Tempat Ini',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Flight Estimation
                  if (_userLocation != null)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: FlightEstimationWidget(
                        userLocation: LatLng(_userLocation!.latitude, _userLocation!.longitude),
                        destinationLocation: LatLng(_place!.lat ?? 0.0, _place!.lng ?? 0.0),
                      ),
                    ),
                  
                  SizedBox(height: 16),
                  
                  // Weather Widget
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prakiraan Cuaca',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        WeatherWidget(weatherData: WeatherData()),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Map Widget
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MapWidget(
                        center: _place!,
                        markers: [_place!],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Reviews Section
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ulasan Pengunjung',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        if (_reviews.isNotEmpty)
                          ...(_reviews.map((review) => _buildReviewItem(review)).toList())
                        else
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Belum ada ulasan untuk tempat ini',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Plan Form
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: PlanFormWidget(place: _place!),
                  ),
                  
                  // Guest warning
                  if (!context.watch<AuthProvider>().isAuthenticated && _viewCount >= 2)
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade50,
                        border: Border.all(color: Colors.yellow.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.yellow.shade700,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Batas View Tercapai',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Anda telah mencapai batas melihat detail tempat sebagai tamu. Login untuk melihat detail tempat lainnya tanpa batas.',
                            style: TextStyle(
                              color: Colors.yellow.shade600,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow.shade700,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 36),
                            ),
                            child: Text('Login Sekarang'),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}