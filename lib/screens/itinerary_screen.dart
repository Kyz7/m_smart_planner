import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/itinerary_provider.dart';
import '../models/itinerary.dart';
import '../widgets/loading_shimmer.dart';

class ItineraryScreen extends StatefulWidget {
  @override
  _ItineraryScreenState createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItineraries();
    });
  }

  Future<void> _loadItineraries() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final itineraryProvider = Provider.of<ItineraryProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      await itineraryProvider.fetchItineraries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildContent(),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isAuthenticated) return SizedBox.shrink();
          
          return FloatingActionButton.extended(
            onPressed: () => _showCreateItineraryDialog(),
            backgroundColor: Color(0xFF2563EB),
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Tambah Rencana', style: TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF2563EB),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Rencana Perjalanan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
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
        ),
      ),
      actions: [
        Consumer<ItineraryProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: provider.isLoading ? null : _loadItineraries,
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return _buildUnauthenticatedState();
        }
        
        return Consumer<ItineraryProvider>(
          builder: (context, itineraryProvider, child) {
            if (itineraryProvider.isLoading && itineraryProvider.itineraries.isEmpty) {
              return _buildLoadingState();
            }
            
            if (itineraryProvider.error.isNotEmpty) {
              return _buildErrorState(itineraryProvider.error);
            }
            
            if (itineraryProvider.itineraries.isEmpty) {
              return _buildEmptyState();
            }
            
            return _buildItinerariesList(itineraryProvider.itineraries);
          },
        );
      },
    );
  }

  Widget _buildUnauthenticatedState() {
    return SliverFillRemaining(
      child: Container(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'Login Diperlukan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Anda perlu login untuk melihat dan mengelola rencana perjalanan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF2563EB),
                      side: BorderSide(color: Color(0xFF2563EB)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Daftar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LoadingShimmer(height: 160),
          ),
          childCount: 3,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SliverFillRemaining(
      child: Container(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            SizedBox(height: 24),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loadItineraries,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Container(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'Belum Ada Rencana',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Mulai merencanakan perjalanan impian Anda dengan menambahkan destinasi wisata',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _showCreateItineraryDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text('Tambah Rencana Pertama', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItinerariesList(List<Itinerary> itineraries) {
    return SliverPadding(
      padding: EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final itinerary = itineraries[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: _buildItineraryCard(itinerary),
            );
          },
          childCount: itineraries.length,
        ),
      ),
    );
  }

  Widget _buildItineraryCard(Itinerary itinerary) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final startDate = DateTime.parse(itinerary.dateRange['from']);
    final endDate = DateTime.parse(itinerary.dateRange['to']);
    final duration = endDate.difference(startDate).inDays + 1;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showItineraryDetail(itinerary),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itinerary.place['name'] ?? 'Destinasi Tidak Dikenal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: 4),
                        if (itinerary.place['formatted_address'] != null)
                          Text(
                            itinerary.place['formatted_address'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, itinerary),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$duration hari',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  if (itinerary.estimatedCost != null && itinerary.estimatedCost! > 0) ...[
                    Icon(Icons.attach_money, color: Colors.green[600], size: 20),
                    SizedBox(width: 4),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(itinerary.estimatedCost)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[600],
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                  if (itinerary.travelers != null) ...[
                    Icon(Icons.people, color: Colors.orange[600], size: 20),
                    SizedBox(width: 4),
                    Text(
                      '${itinerary.travelers!['adults'] ?? 1} orang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItineraryDetail(Itinerary itinerary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildItineraryDetailSheet(itinerary),
    );
  }

  Widget _buildItineraryDetailSheet(Itinerary itinerary) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final startDate = DateTime.parse(itinerary.dateRange['from']);
    final endDate = DateTime.parse(itinerary.dateRange['to']);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  itinerary.place['name'] ?? 'Destinasi Tidak Dikenal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (itinerary.place['formatted_address'] != null) ...[
                    _buildDetailSection(
                      'Lokasi',
                      Icons.location_on,
                      itinerary.place['formatted_address'],
                    ),
                    SizedBox(height: 16),
                  ],
                  if (itinerary.estimatedCost != null && itinerary.estimatedCost! > 0) ...[
                    _buildDetailSection(
                      'Estimasi Biaya',
                      Icons.attach_money,
                      'Rp ${NumberFormat('#,###', 'id_ID').format(itinerary.estimatedCost)}',
                    ),
                    SizedBox(height: 16),
                  ],
                  if (itinerary.travelers != null) ...[
                    _buildDetailSection(
                      'Jumlah Wisatawan',
                      Icons.people,
                      '${itinerary.travelers!['adults'] ?? 1} dewasa${(itinerary.travelers!['children'] ?? 0) > 0 ? ', ${itinerary.travelers!['children']} anak' : ''}',
                    ),
                    SizedBox(height: 16),
                  ],
                  if (itinerary.flight != null) ...[
                    _buildDetailSection(
                      'Informasi Penerbangan',
                      Icons.flight,
                      'Data penerbangan tersedia',
                    ),
                    SizedBox(height: 16),
                  ],
                  _buildDetailSection(
                    'Dibuat',
                    Icons.access_time,
                    DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(itinerary.createdAt),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditItineraryDialog(itinerary);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF2563EB),
                      side: BorderSide(color: Color(0xFF2563EB)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(itinerary);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, String content) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF2563EB), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Itinerary itinerary) {
    switch (action) {
      case 'edit':
        _showEditItineraryDialog(itinerary);
        break;
      case 'delete':
        _showDeleteConfirmation(itinerary);
        break;
    }
  }

  void _showCreateItineraryDialog() {
    // TODO: Implement create itinerary dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur tambah rencana akan segera hadir'),
        backgroundColor: Color(0xFF2563EB),
      ),
    );
  }

  void _showEditItineraryDialog(Itinerary itinerary) {
    // TODO: Implement edit itinerary dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur edit rencana akan segera hadir'),
        backgroundColor: Color(0xFF2563EB),
      ),
    );
  }

  void _showDeleteConfirmation(Itinerary itinerary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Rencana'),
        content: Text('Apakah Anda yakin ingin menghapus rencana perjalanan ke ${itinerary.place['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteItinerary(itinerary);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItinerary(Itinerary itinerary) async {
    final itineraryProvider = Provider.of<ItineraryProvider>(context, listen: false);
    
    try {
      await itineraryProvider.deleteItinerary(itinerary.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rencana perjalanan berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus rencana perjalanan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}