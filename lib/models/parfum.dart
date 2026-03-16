class Parfum {
  final String name;
  final String brand;
  final String? imageUrl;
  final String? gender;
  final String? rating;

  Parfum({
    required this.name,
    required this.brand,
    this.imageUrl,
    this.gender,
    this.rating,
  });

  factory Parfum.fromJson(Map<String, dynamic> json) {
    return Parfum(
      name: json['Name'] ?? 'Unknown Name',
      brand: json['Brand'] ?? 'Unknown Brand',
      imageUrl: json['Image URL'],
      gender: json['Gender'],
      rating: json['rating'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Brand': brand,
      'Image URL': imageUrl,
      'Gender': gender,
      'rating': rating,
    };
  }
}