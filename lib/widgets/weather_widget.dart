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
        children: [
          // Header section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getConditionText(weatherData!.description ?? ''),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[100],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayLocation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[100],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                _getWeatherIcon(weatherData!.description ?? ''),
                style: const TextStyle(fontSize: 48),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Temperature section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weatherData!.temperature?.round() ?? 28}°C',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Saat ini',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[100],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (weatherData!.humidity != null) ...[
                    Column(
                      children: [
                        const Icon(
                          Icons.water_drop,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${weatherData!.humidity}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Kelembaban',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[100],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (weatherData!.windSpeed != null)
                    Column(
                      children: [
                        const Icon(
                          Icons.air,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${weatherData!.windSpeed!.toStringAsFixed(1)} m/s',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Angin',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[100],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
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