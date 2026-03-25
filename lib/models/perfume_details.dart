class PerfumeNote {
  final String name;
  final String? imageUrl;

  const PerfumeNote({required this.name, this.imageUrl});

  factory PerfumeNote.fromJson(Map<String, dynamic> json) {
    return PerfumeNote(
      name: (json['name'] ?? 'Unknown note').toString().trim(),
      imageUrl: _parseNullableString(json['imageUrl']),
    );
  }
}

class PerfumeRanking {
  final String name;
  final double score;

  const PerfumeRanking({required this.name, required this.score});

  factory PerfumeRanking.fromJson(Map<String, dynamic> json) {
    final rawScore = json['score'];
    final parsedScore = rawScore is num
        ? rawScore.toDouble()
        : double.tryParse(rawScore?.toString() ?? '') ?? 0;

    return PerfumeRanking(
      name: (json['name'] ?? 'Unknown').toString().trim(),
      score: parsedScore,
    );
  }
}

class PerfumeDetails {
  final String? id;
  final String name;
  final String brand;
  final String? year;
  final String? rating;
  final String? country;
  final String? imageUrl;
  final List<String> imageFallbacks;
  final String? gender;
  final String? price;
  final String? oilType;
  final String? longevity;
  final String? sillage;
  final String? confidence;
  final String? popularity;
  final String? priceValue;
  final List<String> generalNotes;
  final List<String> mainAccords;
  final Map<String, String> mainAccordLevels;
  final List<PerfumeRanking> seasonRanking;
  final List<PerfumeRanking> occasionRanking;
  final List<PerfumeNote> topNotes;
  final List<PerfumeNote> middleNotes;
  final List<PerfumeNote> baseNotes;
  final String? purchaseUrl;

  const PerfumeDetails({
    this.id,
    required this.name,
    required this.brand,
    this.year,
    this.rating,
    this.country,
    this.imageUrl,
    this.imageFallbacks = const [],
    this.gender,
    this.price,
    this.oilType,
    this.longevity,
    this.sillage,
    this.confidence,
    this.popularity,
    this.priceValue,
    this.generalNotes = const [],
    this.mainAccords = const [],
    this.mainAccordLevels = const {},
    this.seasonRanking = const [],
    this.occasionRanking = const [],
    this.topNotes = const [],
    this.middleNotes = const [],
    this.baseNotes = const [],
    this.purchaseUrl,
  });

  factory PerfumeDetails.fromJson(Map<String, dynamic> json) {
    final notes = json['Notes'];
    final notesMap = notes is Map<String, dynamic>
        ? notes
        : notes is Map
        ? Map<String, dynamic>.from(notes)
        : <String, dynamic>{};

    return PerfumeDetails(
      id: _parseNullableString(
        json['perfumeId'] ?? json['id'] ?? json['_id'] ?? json['ID'],
      ),
      name: (json['Name'] ?? json['name'] ?? 'Unknown fragrance').toString(),
      brand: (json['Brand'] ?? json['brand'] ?? 'Unknown brand').toString(),
      year: _parseNullableString(json['Year'] ?? json['year']),
      rating: _parseNullableString(json['rating'] ?? json['Rating']),
      country: _parseNullableString(json['Country'] ?? json['country']),
      imageUrl: _parseNullableString(json['Image URL'] ?? json['imageUrl']),
      imageFallbacks: _parseStringList(json['Image Fallbacks']),
      gender: _parseNullableString(json['Gender'] ?? json['gender']),
      price: _parseNullableString(json['Price']),
      oilType: _parseNullableString(json['OilType']),
      longevity: _parseNullableString(json['Longevity']),
      sillage: _parseNullableString(json['Sillage']),
      confidence: _parseNullableString(json['Confidence']),
      popularity: _parseNullableString(json['Popularity']),
      priceValue: _parseNullableString(json['Price Value']),
      generalNotes: _parseStringList(json['General Notes']),
      mainAccords: _parseStringList(json['Main Accords']),
      mainAccordLevels: _parseStringMap(json['Main Accords Percentage']),
      seasonRanking: _parseRankingList(json['Season Ranking']),
      occasionRanking: _parseRankingList(json['Occasion Ranking']),
      topNotes: _parseNotesList(notesMap['Top']),
      middleNotes: _parseNotesList(notesMap['Middle']),
      baseNotes: _parseNotesList(notesMap['Base']),
      purchaseUrl: _parseNullableString(json['Purchase URL']),
    );
  }

  String get stableKey {
    final normalizedId = id?.trim();
    if (normalizedId != null && normalizedId.isNotEmpty) {
      return normalizedId.toLowerCase();
    }

    final normalizedYear = year?.trim().toLowerCase() ?? '';
    return '${brand.trim().toLowerCase()}::${name.trim().toLowerCase()}::$normalizedYear';
  }

  String? get heroImageUrl {
    final primary = imageUrl?.trim();
    if (primary != null && primary.isNotEmpty) {
      return primary;
    }

    return imageFallbacks.isEmpty ? null : imageFallbacks.first;
  }

  bool get hasRichDetails {
    return country != null ||
        oilType != null ||
        confidence != null ||
        priceValue != null ||
        generalNotes.isNotEmpty ||
        mainAccords.isNotEmpty ||
        topNotes.isNotEmpty ||
        middleNotes.isNotEmpty ||
        baseNotes.isNotEmpty ||
        seasonRanking.isNotEmpty ||
        occasionRanking.isNotEmpty ||
        purchaseUrl != null;
  }

  bool matches(PerfumeDetails other) {
    return stableKey == other.stableKey ||
        (name.trim().toLowerCase() == other.name.trim().toLowerCase() &&
            brand.trim().toLowerCase() == other.brand.trim().toLowerCase());
  }
}

String? _parseNullableString(dynamic value) {
  if (value == null) return null;

  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  final asString = value.toString().trim();
  return asString.isEmpty ? null : asString;
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return const [];

  if (value is List) {
    return value
        .map((item) => item?.toString().trim())
        .where((item) => item != null && item.isNotEmpty)
        .cast<String>()
        .toList();
  }

  final single = _parseNullableString(value);
  return single == null ? const [] : [single];
}

Map<String, String> _parseStringMap(dynamic value) {
  if (value is! Map) {
    return const {};
  }

  final parsed = <String, String>{};
  for (final entry in value.entries) {
    final key = entry.key.toString().trim();
    final mappedValue = entry.value?.toString().trim() ?? '';

    if (key.isNotEmpty && mappedValue.isNotEmpty) {
      parsed[key] = mappedValue;
    }
  }

  return parsed;
}

List<PerfumeRanking> _parseRankingList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => PerfumeRanking.fromJson(Map<String, dynamic>.from(item)))
      .where((item) => item.name.isNotEmpty)
      .toList();
}

List<PerfumeNote> _parseNotesList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) {
        if (item is Map<String, dynamic>) {
          return PerfumeNote.fromJson(item);
        }
        if (item is Map) {
          return PerfumeNote.fromJson(Map<String, dynamic>.from(item));
        }

        final rawName = item?.toString().trim();
        if (rawName == null || rawName.isEmpty) {
          return null;
        }

        return PerfumeNote(name: rawName);
      })
      .whereType<PerfumeNote>()
      .toList();
}
