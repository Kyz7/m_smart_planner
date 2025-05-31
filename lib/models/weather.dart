class WeatherData {
  final String? location;
  final double? temperature;
  final String? description;
  final String? icon;
  final int? humidity;
  final double? windSpeed;

  WeatherData({
    this.location,
    this.temperature,
    this.description,
    this.icon,
    this.humidity,
    this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: json['location'],
      temperature: json['temperature']?.toDouble(),
      description: json['description'],
      icon: json['icon'],
      humidity: json['humidity'],
      windSpeed: json['wind_speed']?.toDouble(),
    );
  }
}

