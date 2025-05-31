// lib/screens/itinerary_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/itinerary_provider.dart';
import '../providers/auth_provider.dart';
import '../models/itinerary.dart';
import '../utils/format_currency.dart';

class ItineraryScreen extends StatefulWidget {
  @override
  _ItineraryScreenState createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItineraryProvider>().loadPlans();
    });
  }

  String formatDateRange(DateTime from, DateTime to) {
    final formatter = DateFormat('dd MMMM yyyy', 'id_ID');
    return '${formatter.format(from)} - ${formatter.format(to)}';
  }

  int calculateDuration(DateTime from, DateTime to) {
    return to.difference(from).inDays + 1;
  }

  Future<void> _confirmDelete(BuildContext context, String planId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus rencana perjalanan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final success = await context.read<ItineraryProvider>().deletePlan(planId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rencana perjalanan berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus rencana perjalanan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Itinerary Saya'),
        backgroundColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ItineraryProvider>(
        builder: (context, itineraryProvider, child) {
          if (itineraryProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            );
          }

          if (itineraryProvider.error.isNotEmpty) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itineraryProvider.error,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () => itineraryProvider.clearError(),
                        child: Text(
                          'Tutup',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildEmptyState()),
              ],
            );
          }

          if (itineraryProvider.plans.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => itineraryProvider.loadPlans(),
            child: Container(
              color: Colors.grey.shade50,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: itineraryProvider.plans.length,
                itemBuilder: (context, index) {
                  final plan = itineraryProvider.plans[index];
                  return _buildPlanCard(plan);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(24),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada rencana perjalanan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Anda belum memiliki rencana perjalanan yang tersimpan',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Jelajahi Tempat Wisata'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(TravelPlan plan) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
          // Image and title section
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              image: DecorationImage(
                image: NetworkImage(
                  plan.place.photo?.isNotEmpty == true 
                    ? plan.place.photo! 
                    : "https://via.placeholder.com/800x400?text=No+Image"
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.place.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (plan.place.address?.isNotEmpty == true)
                    Text(
                      plan.place.address ?? 'Alamat tidak tersedia',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Details section
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date range
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formatDateRange(plan.dateRange.from, plan.dateRange.to),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Duration
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${calculateDuration(plan.dateRange.from, plan.dateRange.to)} hari',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                // Flight info if available
                if (plan.flight != null) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.flight,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Penerbangan: ${plan.flight!.origin} - ${plan.flight!.destination}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                SizedBox(height: 16),
                
                // Cost and actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimasi Biaya',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(plan.estimatedCost),
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    // Delete button
                    IconButton(
                      onPressed: () => _confirmDelete(context, plan.id!),
                      icon: Icon(Icons.delete_outline),
                      color: Colors.red,
                      tooltip: 'Hapus rencana',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}