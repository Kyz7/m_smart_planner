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

  // ✅ FIXED: Improved toJson with all necessary fields
  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'name': name,
      'address': address,
      'photo': photo,
      'thumbnail': thumbnail,
      'serpapi_thumbnail': serpapiThumbnail,
      'image_url': imageUrl, // ✅ ADDED: Include computed imageUrl
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'price_level': priceLevel,
      'types': types,
      'location': hasValidCoordinates ? {
        'lat': lat,
        'lng': lng,
      } : null, // ✅ ADDED: Structured location object
      'lat': lat,
      'lng': lng,
      'price': price,
    };
  }

  // ✅ IMPROVED: More comprehensive coordinate validation
  bool get hasValidCoordinates {
    return lat != null && lng != null && 
           lat!.isFinite && lng!.isFinite &&
           lat! >= -90 && lat! <= 90 &&
           lng! >= -180 && lng! <= 180;
  }

  // Helper method untuk format alamat
  String get formattedAddress {
    return address?.isNotEmpty == true ? address! : 'Alamat tidak tersedia';
  }

  // Helper method untuk format rating
  String get formattedRating {
    if (rating == null) return '0.0';
    return rating!.toStringAsFixed(1);
  }

  // ✅ ADDED: Helper method untuk format price
  String get formattedPrice {
    if (price == null) return 'Harga tidak tersedia';
    return 'Rp ${price!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // ✅ ADDED: Method to create minimal JSON for API requests
  Map<String, dynamic> toMinimalJson() {
    return {
      'name': name,
      'address': formattedAddress,
      'location': {
        'lat': lat ?? -6.2088,
        'lng': lng ?? 106.8456,
      },
      'rating': rating,
      'photo': imageUrl,
      'price': price,
      'place_id': placeId,
      'types': types,
    };
  }
}