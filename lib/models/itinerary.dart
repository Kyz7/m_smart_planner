import 'place.dart';
class TravelPlan {
  final String? id;
  final Place place;
  final DateRange dateRange;
  final FlightInfo? flight;
  final double estimatedCost;
  final DateTime? createdAt;

  TravelPlan({
    this.id,
    required this.place,
    required this.dateRange,
    this.flight,
    required this.estimatedCost,
    this.createdAt,
  });

  factory TravelPlan.fromJson(Map<String, dynamic> json) {
    return TravelPlan(
      id: json['_id'],
      place: Place.fromJson(json['place']),
      dateRange: DateRange.fromJson(json['dateRange']),
      flight: json['flight'] != null ? FlightInfo.fromJson(json['flight']) : null,
      estimatedCost: json['estimatedCost']?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  int get duration {
    return dateRange.to.difference(dateRange.from).inDays + 1;
  }
}

class DateRange {
  final DateTime from;
  final DateTime to;

  DateRange({required this.from, required this.to});

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      from: DateTime.parse(json['from']),
      to: DateTime.parse(json['to']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    };
  }
}

class FlightInfo {
  final String origin;
  final String destination;
  final double? price;

  FlightInfo({
    required this.origin,
    required this.destination,
    this.price,
  });

  factory FlightInfo.fromJson(Map<String, dynamic> json) {
    return FlightInfo(
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      price: json['price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'price': price,
    };
  }
}