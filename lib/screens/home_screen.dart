import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/places_provider.dart';
import '../widgets/search_bar.dart';
import '../widgets/weather_widget.dart';
import '../widgets/place_card.dart';
import '../widgets/loading_shimmer.dart';
import '../models/place.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMorePlaces();
    }
  }

  void _loadMorePlaces() {
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!placesProvider.isLoading && 
        placesProvider.pagination['hasNextPage'] == true &&
        (authProvider.isAuthenticated || placesProvider.searchCount < 2)) {
      
      _currentPage++;
      placesProvider.fetchNearbyPlaces(
        placesProvider.currentPosition!.latitude,
        placesProvider.currentPosition!.longitude,
        page: _currentPage,
      );
    }
  }

  void _onSearch(double lat, double lng, String query) {
    setState(() {
      _currentPage = 1;
    });
    
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    placesProvider.searchPlaces(lat, lng, query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          _buildHeroSection(),
          _buildWeatherSection(),
          _buildErrorSection(),
          _buildPlacesSection(),
          _buildFooterSection(),
        ],
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildAppBar() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SliverAppBar(
          expandedHeight: 0,
          floating: true,
          backgroundColor: Color(0xFF2563EB),
          title: Text('Travel Planner'),
          actions: [
            if (authProvider.isAuthenticated) ...[
              IconButton(
                icon: Icon(Icons.list_alt),
                onPressed: () => Navigator.pushNamed(context, '/itinerary'),
              ),
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(authProvider),
              ),
            ] else ...[
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text('Login', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2563EB),
              Color(0xFF1D4ED8),
              Color(0xFF7C3AED),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 20),
              Text(
                'Temukan Destinasi Wisatamu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Rencanakan perjalanan sempurna dengan informasi lengkap cuaca, harga, dan lokasi',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              SearchBarWidget(onSearch: _onSearch),
              SizedBox(height: 16),
              _buildSearchLimitInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchLimitInfo() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) return SizedBox.shrink();
        
        return Consumer<PlacesProvider>(
          builder: (context, placesProvider, child) {
            final remaining = 2 - placesProvider.searchCount;
            
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                remaining > 0 
                  ? 'Sisa pencarian: $remaining kali. Login untuk pencarian tanpa batas.'
                  : 'Batas pencarian tercapai. Login untuk melanjutkan.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeatherSection() {
    return Consumer<PlacesProvider>(
      builder: (context, placesProvider, child) {
        if (placesProvider.weather == null) return SliverToBoxAdapter(child: SizedBox.shrink());
        
        return SliverToBoxAdapter(
          child: Transform.translate(
            offset: Offset(0, -30),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: WeatherWidget(
                weatherData: placesProvider.weather!,
                locationName: placesProvider.currentLocationName,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorSection() {
    return Consumer<PlacesProvider>(
      builder: (context, placesProvider, child) {
        if (placesProvider.error.isEmpty) return SliverToBoxAdapter(child: SizedBox.shrink());
        
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      placesProvider.error,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlacesSection() {
  return Consumer<PlacesProvider>(
    builder: (context, placesProvider, child) {
      return SliverPadding(
        padding: EdgeInsets.all(20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              // Title section
              if (index == 0) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Destinasi Wisata Populer',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                );
              }

              final placeIndex = index - 1;

              // Loading state when no places yet
              if (placesProvider.isLoading && placesProvider.places.isEmpty) {
                if (placeIndex == 0) {
                  return LoadingShimmer();
                }
                return SizedBox.shrink(); // Return empty widget instead of null
              }

              // Empty state
              if (placesProvider.places.isEmpty && !placesProvider.isLoading) {
                if (placeIndex == 0) {
                  return _buildEmptyState();
                }
                return SizedBox.shrink(); // Return empty widget instead of null
              }

              // Places list
              if (placeIndex < placesProvider.places.length) {
                final place = placesProvider.places[placeIndex];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: PlaceCard(
                    place: place,
                    onTap: () => _navigateToDetail(place),
                  ),
                );
              }

              // Loading more indicator
              if (placesProvider.isLoading && 
                  placeIndex == placesProvider.places.length &&
                  placesProvider.places.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Fallback - return empty widget instead of null
              return SizedBox.shrink();
            },
            childCount: _calculateChildCount(placesProvider),
          ),
        ),
      );
    },
  );
}

int _calculateChildCount(PlacesProvider placesProvider) {
  // Always include title (index 0)
  int count = 1;
  
  if (placesProvider.isLoading && placesProvider.places.isEmpty) {
    // Title + LoadingShimmer
    count += 1;
  } else if (placesProvider.places.isEmpty && !placesProvider.isLoading) {
    // Title + EmptyState
    count += 1;
  } else {
    // Title + Places + optional loading indicator
    count += placesProvider.places.length;
    if (placesProvider.isLoading) {
      count += 1; // Loading more indicator
    }
  }
  
  return count;
}

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tidak ada destinasi ditemukan.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.only(top: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF1D4ED8),
                  Color(0xFF7C3AED),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Text(
                    'Sudah siap untuk berpetualang?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Simpan rencana perjalananmu dan akses kapan saja',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  if (!authProvider.isAuthenticated) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF2563EB),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text('Daftar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/itinerary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF2563EB),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: Text('Lihat Rencana Perjalanan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.explore, size: 48, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Travel Planner',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (authProvider.isAuthenticated)
                      Text(
                        'Welcome back!',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Beranda'),
                onTap: () => Navigator.pop(context),
              ),
              if (authProvider.isAuthenticated) ...[
                ListTile(
                  leading: Icon(Icons.list_alt),
                  title: Text('Rencana Perjalanan'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/itinerary');
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(authProvider);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Icon(Icons.login),
                  title: Text('Login'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/login');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Daftar Akun'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/register');
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetail(Place place) {
    Navigator.pushNamed(
      context,
      '/detail/${place.placeId}',
      arguments: place,
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Berhasil logout')),
              );
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}