// lib/utils/route_extensions.dart
import 'package:flutter/material.dart';
import '../models/place.dart';

extension RouteSettingsExtension on RouteSettings {
  /// Safely get Place from route arguments
  Place? get place {
    if (arguments is Place) {
      return arguments as Place;
    }
    return null;
  }
  
  /// Get Place with required validation
  Place getPlaceOrThrow() {
    final place = this.place;
    if (place == null) {
      throw ArgumentError('Expected Place argument but got ${arguments.runtimeType}');
    }
    return place;
  }
}

extension BuildContextExtension on BuildContext {
  /// Get Place from current route arguments
  Place? get routePlace {
    return ModalRoute.of(this)?.settings.place;
  }
  
  /// Get Place with required validation
  Place getRoutePlaceOrThrow() {
    final place = routePlace;
    if (place == null) {
      throw ArgumentError('No Place found in route arguments');
    }
    return place;
  }
}