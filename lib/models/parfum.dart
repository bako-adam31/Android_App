class Parfum {
  final String? id;
  final String name;
  final String brand;
  final String? imageUrl;
  final String? gender;
  final String? rating;
  final String? year;
  final String? price;
  final String? oilType;
  final String? longevity;
  final String? sillage;
  final String? topNotes;
  final String? middleNotes;
  final String? baseNotes;
  final String? mainAccords;
  final String? popularity;

  Parfum({
    this.id,
    required this.name,
    required this.brand,
    this.imageUrl,
    this.gender,
    this.rating,
    this.year,
    this.price,
    this.oilType,
    this.longevity,
    this.sillage,
    this.topNotes,
    this.middleNotes,
    this.baseNotes,
    this.mainAccords,
    this.popularity,
  });

  static String? _parseSimple(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (value is List) {
      final parts = value
          .map((e) => e?.toString().trim())
          .where((e) => e != null && e.isNotEmpty)
          .cast<String>()
          .toList();

      return parts.isEmpty ? null : parts.join(', ');
    }

    return value.toString();
  }

  static String? _parseNotesArray(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      final names = value
          .map((item) {
            if (item is Map<String, dynamic>) {
              return item['name']?.toString().trim();
            }
            if (item is Map) {
              return item['name']?.toString().trim();
            }
            return item?.toString().trim();
          })
          .where((e) => e != null && e.isNotEmpty)
          .cast<String>()
          .toList();

      return names.isEmpty ? null : names.join(', ');
    }

    return _parseSimple(value);
  }

  factory Parfum.fromJson(Map<String, dynamic> json) {
    final notes = json['Notes'];
    Map<String, dynamic> notesMap = {};

    if (notes is Map<String, dynamic>) {
      notesMap = notes;
    } else if (notes is Map) {
      notesMap = Map<String, dynamic>.from(notes);
    }

    return Parfum(
      id:
          _parseSimple(json['perfumeId']) ??
          _parseSimple(json['id']) ??
          _parseSimple(json['_id']) ??
          _parseSimple(json['ID']),
      name: (json['Name'] ?? json['name'] ?? 'Unknown Name').toString(),
      brand: (json['Brand'] ?? json['brand'] ?? 'Unknown Brand').toString(),
      imageUrl: _parseSimple(json['Image URL'] ?? json['imageUrl']),
      gender: _parseSimple(json['Gender'] ?? json['gender']),
      rating: _parseSimple(json['rating'] ?? json['Rating']),
      year: _parseSimple(json['Year'] ?? json['year']),
      price: _parseSimple(json['Price']),
      oilType: _parseSimple(json['OilType']),
      longevity: _parseSimple(json['Longevity']),
      sillage: _parseSimple(json['Sillage']),
      popularity: _parseSimple(json['Popularity']),
      topNotes:
          _parseNotesArray(notesMap['Top']) ?? _parseSimple(json['Top Notes']),
      middleNotes:
          _parseNotesArray(notesMap['Middle']) ??
          _parseSimple(json['Middle Notes']),
      baseNotes:
          _parseNotesArray(notesMap['Base']) ??
          _parseSimple(json['Base Notes']),
      mainAccords: _parseSimple(json['Main Accords'] ?? json['mainAccords']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'perfumeId': id,
      'id': id,
      'Name': name,
      'Brand': brand,
      'Image URL': imageUrl,
      'Gender': gender,
      'rating': rating,
      'Year': year,
      'Price': price,
      'OilType': oilType,
      'Longevity': longevity,
      'Sillage': sillage,
      'Popularity': popularity,
      'Top Notes': topNotes,
      'Middle Notes': middleNotes,
      'Base Notes': baseNotes,
      'Main Accords': mainAccords,
    };
  }

  Map<String, dynamic> toProfileSignatureJson() {
    return {
      'perfumeId': id,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'gender': gender,
      'rating': rating,
      'year': year,
      'mainAccords': mainAccords,
    };
  }

  String get stableKey {
    final normalizedId = id?.trim();
    if (normalizedId != null && normalizedId.isNotEmpty) {
      return normalizedId.toLowerCase();
    }
    return '${brand.trim().toLowerCase()}::${name.trim().toLowerCase()}';
  }
}
