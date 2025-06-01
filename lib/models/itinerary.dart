import 'place.dart';
class TravelPlan {
  final String id;
  final Place place;
  final DateRange dateRange;
  final double estimatedCost;
  final String? weather;
  final Flight? flight;
  final Travelers? travelers; // ✅ ADDED: travelers field
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Duration? duration; // ✅ ADDED: duration field

  TravelPlan({
    required this.id,
    required this.place,
    required this.dateRange,
    required this.estimatedCost,
    this.weather,
    this.flight,
    this.travelers, // ✅ ADDED: travelers parameter
    this.createdAt,
    this.updatedAt,
    this.duration, // ✅ ADDED: duration parameter
  });

  factory TravelPlan.fromJson(Map<String, dynamic> json) {
    return TravelPlan(
      id: json['id'].toString(),
      place: Place.fromJson(json['place'] ?? {}),
      dateRange: DateRange.fromJson(json['dateRange'] ?? {}),
      estimatedCost: (json['estimatedCost'] ?? 0).toDouble(),
      weather: json['weather'],
      flight: json['flight'] != null ? Flight.fromJson(json['flight']) : null,
      travelers: json['travelers'] != null ? Travelers.fromJson(json['travelers']) : null, // ✅ ADDED
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place': place.toJson(),
      'dateRange': dateRange.toJson(),
      'estimatedCost': estimatedCost,
      if (weather != null) 'weather': weather,
      if (flight != null) 'flight': flight!.toJson(),
      if (travelers != null) 'travelers': travelers!.toJson(), // ✅ ADDED
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

class Location {
  final double lat;
  final double lng;

  Location({
    required this.lat,
    required this.lng,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

class DateRange {
  final DateTime from;
  final DateTime to;

  DateRange({
    required this.from,
    required this.to,
  });

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

class Flight {
  final String origin;
  final String destination;
  final double cost; // ✅ CHANGED: from 'price' to 'cost' to match React

  Flight({
    required this.origin,
    required this.destination,
    required this.cost,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      cost: (json['cost'] ?? 0).toDouble(), // ✅ CHANGED: from 'price' to 'cost'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'cost': cost, // ✅ CHANGED: from 'price' to 'cost'
    };
  }
}

// ✅ ADDED: Travelers class
class Travelers {
  final int adults;
  final int children;

  Travelers({
    required this.adults,
    required this.children,
  });

  factory Travelers.fromJson(Map<String, dynamic> json) {
    return Travelers(
      adults: json['adults'] ?? 1,
      children: json['children'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adults': adults,
      'children': children,
    };
  }
}