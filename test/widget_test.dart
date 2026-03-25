import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_vizsgaprojekt/models/accord_category.dart';
import 'package:flutter_vizsgaprojekt/models/parfum.dart';
import 'package:flutter_vizsgaprojekt/models/perfume_details.dart';
import 'package:flutter_vizsgaprojekt/models/profile_details.dart';

void main() {
  test('AccordCategories.byId resolves ids, labels, and API accords', () {
    expect(AccordCategories.byId('woody'), AccordCategories.woody);
    expect(AccordCategories.byId('Warm Spicy'), AccordCategories.warmSpicy);
    expect(AccordCategories.byId('warm spicy'), AccordCategories.warmSpicy);
    expect(AccordCategories.byId('unknown'), isNull);
  });

  test('ProfileDetails serializes signature fragrance and favorite accord', () {
    final profile = ProfileDetails(
      bio: 'Collector of warm woody scents.',
      gender: ProfileGender.female,
      favoriteAccord: AccordCategories.amber,
      signatureFragrance: Parfum(
        id: 'oud-wood',
        name: 'Oud Wood',
        brand: 'Tom Ford',
        mainAccords: 'Woody, Amber',
      ),
    );

    final restored = ProfileDetails.fromJson(profile.toJson());

    expect(restored.bio, profile.bio);
    expect(restored.gender, ProfileGender.female);
    expect(restored.favoriteAccord, AccordCategories.amber);
    expect(restored.signatureFragrance?.name, 'Oud Wood');
    expect(
      profile.toApiJson()['signatureFragrance'],
      containsPair('brand', 'Tom Ford'),
    );
  });

  test('PerfumeDetails parses rich fragrance API payload', () {
    final perfume = PerfumeDetails.fromJson({
      'Name': 'Blend Oud Gold Oud',
      'Brand': 'Blend Oud',
      'Year': '2018',
      'rating': '4.01',
      'Country': 'Italy',
      'Image URL': 'https://cdn.fragella.com/images/blend-oud-gold-oud.jpg',
      'Gender': 'unisex',
      'Price': '144.99',
      'OilType': 'Eau de Parfum',
      'Longevity': 'Long Lasting',
      'Sillage': 'Strong',
      'Confidence': 'medium',
      'Popularity': 'Medium',
      'Price Value': 'okay',
      'General Notes': ['lemon', 'jasmine'],
      'Main Accords': ['woody', 'oud'],
      'Main Accords Percentage': {'woody': 'Dominant', 'oud': 'Prominent'},
      'Season Ranking': [
        {'name': 'winter', 'score': 2.064},
      ],
      'Occasion Ranking': [
        {'name': 'night out', 'score': 0.952},
      ],
      'Notes': {
        'Top': [
          {
            'name': 'Lemon',
            'imageUrl': 'https://cdn.fragella.com/note_images/Lemon.png',
          },
        ],
        'Middle': [
          {
            'name': 'Rose',
            'imageUrl': 'https://cdn.fragella.com/note_images/Rose.png',
          },
        ],
        'Base': [
          {
            'name': 'Patchouli',
            'imageUrl': 'https://cdn.fragella.com/note_images/Patchouli.png',
          },
        ],
      },
      'Image Fallbacks': ['https://cdn.fragrancenet.com/images/fallback.jpg'],
      'Purchase URL': 'https://www.fragrancenet.com/example',
    });

    expect(perfume.name, 'Blend Oud Gold Oud');
    expect(perfume.country, 'Italy');
    expect(perfume.generalNotes, contains('lemon'));
    expect(perfume.mainAccordLevels['woody'], 'Dominant');
    expect(perfume.topNotes.first.name, 'Lemon');
    expect(perfume.seasonRanking.first.name, 'winter');
    expect(perfume.purchaseUrl, 'https://www.fragrancenet.com/example');
    expect(perfume.hasRichDetails, isTrue);
  });
}
