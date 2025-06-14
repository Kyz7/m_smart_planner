import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';

class WeatherWidget extends StatelessWidget {
  final WeatherData? weatherData;
  final String? locationName;

  const WeatherWidget({
    Key? key,
    this.weatherData,
    this.locationName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (weatherData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Informasi cuaca tidak tersedia saat ini'),
        ),
      );
    }

    final displayLocation = locationName ?? 
                           weatherData!.location ?? 
                           'Lokasi saat ini';
    
    final currentDate = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20), // Add margin for spacing
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[500]!,
            Colors.blue[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          // Header section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getConditionText(weatherData!.description ?? ''),
                      style: const TextStyle(
                        fontSize: 20, // Slightly smaller to prevent overflow
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[100],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayLocation,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[100],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    _getWeatherIcon(weatherData!.description ?? ''),
                    style: const TextStyle(fontSize: 40), // Smaller icon
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // Reduced spacing
          // Temperature and details section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${weatherData!.temperature?.round() ?? 28}°C',
                        style: const TextStyle(
                          fontSize: 32, // Slightly smaller
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      'Saat ini',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[100],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (weatherData!.humidity != null)
                      Flexible(
                        child: _buildWeatherDetail(
                          Icons.water_drop,
                          '${weatherData!.humidity}%',
                          'Kelembaban',
                        ),
                      ),
                    if (weatherData!.windSpeed != null)
                      Flexible(
                        child: _buildWeatherDetail(
                          Icons.air,
                          '${weatherData!.windSpeed!.toStringAsFixed(1)} m/s',
                          'Angin',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.blue[100],
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  String _getConditionText(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('clear') || desc.contains('sunny')) return 'Cerah';
    if (desc.contains('partly cloudy')) return 'Cerah Berawan';
    if (desc.contains('cloudy') || desc.contains('overcast')) return 'Berawan';
    if (desc.contains('fog') || desc.contains('mist')) return 'Berkabut';
    if (desc.contains('drizzle')) return 'Gerimis';
    if (desc.contains('rain')) {
      if (desc.contains('heavy')) return 'Hujan Lebat';
      return 'Hujan';
    }
    if (desc.contains('thunderstorm') || desc.contains('storm')) return 'Badai Petir';
    if (desc.contains('snow')) return 'Bersalju';
    return description.isNotEmpty ? description : 'Cerah';
  }

  String _getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('clear') || desc.contains('sunny')) return '☀️';
    if (desc.contains('partly cloudy')) return '🌤️';
    if (desc.contains('cloudy') || desc.contains('overcast')) return '☁️';
    if (desc.contains('fog') || desc.contains('mist')) return '🌫️';
    if (desc.contains('drizzle')) return '🌦️';
    if (desc.contains('rain')) {
      if (desc.contains('heavy')) return '🌧️';
      return '🌧️';
    }
    if (desc.contains('thunderstorm') || desc.contains('storm')) return '⛈️';
    if (desc.contains('snow')) return '🌨️';
    return '☀️'; // default
  }
}