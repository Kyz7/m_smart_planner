class Place {
  final String? placeId;
  final String name;
  final String? address;
  final String? photo;
  final String? thumbnail;
  final String? serpapiThumbnail;
  final double? rating;
  final int? userRatingsTotal;
  final String? priceLevel;
  final List<String>? types;
  final double? lat;
  final double? lng;
  final double? price;

  Place({
    this.placeId,
    required this.name,
    this.address,
    this.photo,
    this.thumbnail,
    this.serpapiThumbnail,
    this.rating,
    this.userRatingsTotal,
    this.priceLevel,
    this.types,
    this.lat,
    this.lng,
    this.price,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      placeId: json['place_id'],
      name: json['name'] ?? json['title'] ?? '',
      address: json['address'] ?? json['vicinity'] ?? '',
      photo: json['photo'],
      thumbnail: json['thumbnail'],
      serpapiThumbnail: json['serpapi_thumbnail'],
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      priceLevel: json['price_level'],
      types: json['types'] != null ? List<String>.from(json['types']) : null,
      lat: json['geometry']?['location']?['lat']?.toDouble() ?? 
           json['location']?['lat']?.toDouble() ?? 
           json['lat']?.toDouble(),
      lng: json['geometry']?['location']?['lng']?.toDouble() ?? 
           json['location']?['lng']?.toDouble() ?? 
           json['lng']?.toDouble(),
      price: json['price']?.toDouble(),
    );
  }

  String get imageUrl {
    return serpapiThumbnail ?? 
           thumbnail ?? 
           photo ?? 
           'https://via.placeholder.com/400x300?text=No+Image';
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'name': name,
      'address': address,
      'photo': photo,
      'thumbnail': thumbnail,
      'serpapi_thumbnail': serpapiThumbnail,
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'price_level': priceLevel,
      'types': types,
      'lat': lat,
      'lng': lng,
      'price': price,
    };
  }

  // Helper method untuk mendapatkan koordinat yang valid
  bool get hasValidCoordinates {
    return lat != null && lng != null;
  }

  // Helper method untuk format alamat
  String get formattedAddress {
    return address ?? 'Alamat tidak tersedia';
  }

  // Helper method untuk format rating
  String get formattedRating {
    if (rating == null) return '0.0';
    return rating!.toStringAsFixed(1);
  }
}