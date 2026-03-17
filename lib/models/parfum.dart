class Parfum {
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


  Parfum({
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
  });

  factory Parfum.fromJson(Map<String, dynamic> json) {
    return Parfum(
      name: json['Name'] ?? 'Unknown Name',
      brand: json['Brand'] ?? 'Unknown Brand',
      imageUrl: json['Image URL'],
      gender: json['Gender'],
      rating: json['rating'],
      year: json['Year'],
      price: json['Price'],
      oilType: json['OilType'],
      longevity: json['Longevity'],
      sillage: json['Sillage'],
      topNotes: json['Top Notes'],
      middleNotes: json['Middle Notes'],
      baseNotes: json['Base Notes'],
      mainAccords: json['Main Accords'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'Top notes': topNotes,
      'Middle notes': middleNotes,
      'Base notes': baseNotes,
      'Main Accords': mainAccords,

    };
  }
}