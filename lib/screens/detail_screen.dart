import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailScreen({
    Key? key,
    required this.place,
  }) : super(key: key);

  @override
  _PlaceDetailScreenState createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  bool _isAddingToItinerary = false;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

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
    if (_scrollController.offset > 200 && !_showAppBarTitle) {
      setState(() {
        _showAppBarTitle = true;
      });
    } else if (_scrollController.offset <= 200 && _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          _buildContent(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      title: _showAppBarTitle
          ? Text(
              widget.place.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.place.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            // Rating badge
            if (widget.place.rating != null)
              Positioned(
                top: 100,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 18, color: Colors.black87),
                      SizedBox(width: 4),
                      Text(
                        widget.place.formattedRating,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (widget.place.userRatingsTotal != null) ...[
                        SizedBox(width: 4),
                        Text(
                          '(${widget.place.userRatingsTotal})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SliverPadding(
      padding: EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildTitleSection(),
          SizedBox(height: 24),
          _buildInfoCards(),
          SizedBox(height: 24),
          _buildLocationSection(),
          SizedBox(height: 24),
          _buildTypesSection(),
          SizedBox(height: 24),
          _buildActionButtons(),
          SizedBox(height: 80), // Space for FAB
        ]),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.place.name,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, size: 20, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.place.formattedAddress,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        if (widget.place.rating != null)
          Expanded(
            child: _buildInfoCard(
              icon: Icons.star,
              iconColor: Colors.amber,
              title: 'Rating',
              value: widget.place.formattedRating,
              subtitle: widget.place.userRatingsTotal != null
                  ? '${widget.place.userRatingsTotal} ulasan'
                  : null,
            ),
          ),
        if (widget.place.rating != null && widget.place.price != null)
          SizedBox(width: 12),
        if (widget.place.price != null)
          Expanded(
            child: _buildInfoCard(
              icon: Icons.attach_money,
              iconColor: Colors.green,
              title: 'Harga',
              value: widget.place.formattedPrice,
            ),
          ),
        if (widget.place.priceLevel != null &&
            (widget.place.rating == null && widget.place.price == null))
          Expanded(
            child: _buildInfoCard(
              icon: Icons.monetization_on,
              iconColor: Colors.green,
              title: 'Tingkat Harga',
              value: _getPriceLevelText(widget.place.priceLevel!),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        children: [
          Icon(icon, size: 32, color: iconColor),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    if (!widget.place.hasValidCoordinates) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                'Lokasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Koordinat: ${widget.place.lat!.toStringAsFixed(6)}, ${widget.place.lng!.toStringAsFixed(6)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInMaps,
              icon: Icon(Icons.directions),
              label: Text('Buka di Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypesSection() {
    if (widget.place.types == null || widget.place.types!.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: Colors.purple, size: 24),
              SizedBox(width: 12),
              Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.place.types!
                .map((type) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple[200]!),
                      ),
                      child: Text(
                        type.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.purple[700],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 32),
                SizedBox(height: 8),
                Text(
                  'Login untuk menambahkan ke rencana perjalanan',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Login Sekarang'),
                ),
              ],
            ),
          );
        }

        return SizedBox.shrink();
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: _isAddingToItinerary ? null : _addToItinerary,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          icon: _isAddingToItinerary
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.add),
          label: Text(_isAddingToItinerary ? 'Menambahkan...' : 'Tambah ke Rencana'),
        );
      },
    );
  }

  String _getPriceLevelText(String priceLevel) {
    switch (priceLevel) {
      case '1':
        return 'Murah (\$)';
      case '2':
        return 'Sedang (\$\$)';
      case '3':
        return 'Mahal (\$\$\$)';
      case '4':
        return 'Sangat Mahal (\$\$\$\$)';
      default:
        return 'Tidak diketahui';
    }
  }

  void _openInMaps() async {
    if (!widget.place.hasValidCoordinates) return;

    final url = 'https://www.google.com/maps/search/?api=1&query=${widget.place.lat},${widget.place.lng}';
    
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        _showErrorSnackBar('Tidak dapat membuka aplikasi Maps');
      }
    } catch (e) {
      _showErrorSnackBar('Error membuka Maps: $e');
    }
  }

  void _addToItinerary() async {
    setState(() {
      _isAddingToItinerary = true;
    });

    try {
      await ApiService.addToItinerary(widget.place.toMinimalJson());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.place.name} berhasil ditambahkan ke rencana perjalanan'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Lihat',
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/itinerary'),
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Gagal menambahkan ke rencana perjalanan: $e');
    } finally {
      setState(() {
        _isAddingToItinerary = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}