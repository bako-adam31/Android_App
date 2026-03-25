class AccordCategory {
  final String id;
  final String label;
  final String apiAccord;
  final String icon;
  final String subtitle;
  final List<int> fallbackLevels;
  final String seenKey;

  const AccordCategory({
    required this.id,
    required this.label,
    required this.apiAccord,
    required this.icon,
    required this.subtitle,
    required this.seenKey,
    this.fallbackLevels = const [100, 90, 80],
  });
}

class AccordCategories {
  static const woody = AccordCategory(
    id: 'woody',
    label: 'Woody',
    apiAccord: 'woody',
    icon: '🌲',
    subtitle: 'Rich woods with smart fallback loading',
    seenKey: 'seen_woody',
  );

  static const gourmand = AccordCategory(
    id: 'gourmand',
    label: 'Gourmand',
    apiAccord: 'gourmand',
    icon: '🍮',
    subtitle: 'Sweet, edible, dessert-like scents',
    seenKey: 'seen_gourmand',
  );

  static const citrus = AccordCategory(
    id: 'citrus',
    label: 'Citrus',
    apiAccord: 'citrus',
    icon: '🍋',
    subtitle: 'Fresh, zesty, energizing',
    seenKey: 'seen_citrus',
  );

  static const warmSpicy = AccordCategory(
    id: 'warm_spicy',
    label: 'Warm Spicy',
    apiAccord: 'warm spicy',
    icon: '🌶️',
    subtitle: 'Hot spices and warmth',
    seenKey: 'seen_warm_spicy',
  );

  static const fruity = AccordCategory(
    id: 'fruity',
    label: 'Fruity',
    apiAccord: 'fruity',
    icon: '🍑',
    subtitle: 'Juicy, playful, vibrant',
    seenKey: 'seen_fruity',
  );

  static const aromatic = AccordCategory(
    id: 'aromatic',
    label: 'Aromatic',
    apiAccord: 'aromatic',
    icon: '🌿',
    subtitle: 'Herbal, clean, uplifting',
    seenKey: 'seen_aromatic',
  );

  static const leather = AccordCategory(
    id: 'leather',
    label: 'Leather',
    apiAccord: 'leather',
    icon: '🧥',
    subtitle: 'Dark, textured, bold',
    seenKey: 'seen_leather',
  );

  static const smoky = AccordCategory(
    id: 'smoky',
    label: 'Smoky',
    apiAccord: 'smoky',
    icon: '🔥',
    subtitle: 'Burnt, mysterious, intense',
    seenKey: 'seen_smoky',
  );

  static const amber = AccordCategory(
    id: 'amber',
    label: 'Amber',
    apiAccord: 'amber',
    icon: '🟠',
    subtitle: 'Warm resinous depth',
    seenKey: 'seen_amber',
  );

  static const all = <AccordCategory>[
    woody,
    gourmand,
    citrus,
    warmSpicy,
    fruity,
    aromatic,
    leather,
    smoky,
    amber,
  ];

  static AccordCategory? byId(String? value) {
    if (value == null) return null;

    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final category in all) {
      if (category.id == normalized ||
          category.apiAccord == normalized ||
          category.label.toLowerCase() == normalized) {
        return category;
      }
    }

    return null;
  }
}
