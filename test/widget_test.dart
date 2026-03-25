import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_vizsgaprojekt/models/accord_category.dart';
import 'package:flutter_vizsgaprojekt/models/parfum.dart';
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
}
