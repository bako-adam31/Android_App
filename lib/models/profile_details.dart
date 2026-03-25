import 'accord_category.dart';
import 'parfum.dart';

enum ProfileGender {
  male('male'),
  female('female');

  const ProfileGender(this.value);

  final String value;

  String get label => value[0].toUpperCase() + value.substring(1);

  static ProfileGender? fromValue(String? value) {
    if (value == null) return null;

    for (final gender in ProfileGender.values) {
      if (gender.value == value.trim().toLowerCase()) {
        return gender;
      }
    }

    return null;
  }
}

class ProfileDetails {
  final String bio;
  final ProfileGender? gender;
  final AccordCategory? favoriteAccord;
  final Parfum? signatureFragrance;

  const ProfileDetails({
    this.bio = '',
    this.gender,
    this.favoriteAccord,
    this.signatureFragrance,
  });

  const ProfileDetails.empty()
    : bio = '',
      gender = null,
      favoriteAccord = null,
      signatureFragrance = null;

  bool get hasBio => bio.trim().isNotEmpty;

  bool get hasDetails =>
      hasBio ||
      gender != null ||
      favoriteAccord != null ||
      signatureFragrance != null;

  ProfileDetails copyWith({
    String? bio,
    Object? gender = _sentinel,
    Object? favoriteAccord = _sentinel,
    Object? signatureFragrance = _sentinel,
  }) {
    return ProfileDetails(
      bio: bio ?? this.bio,
      gender: identical(gender, _sentinel)
          ? this.gender
          : gender as ProfileGender?,
      favoriteAccord: identical(favoriteAccord, _sentinel)
          ? this.favoriteAccord
          : favoriteAccord as AccordCategory?,
      signatureFragrance: identical(signatureFragrance, _sentinel)
          ? this.signatureFragrance
          : signatureFragrance as Parfum?,
    );
  }

  factory ProfileDetails.fromJson(Map<String, dynamic> json) {
    final signatureData = json['signatureFragrance'];

    return ProfileDetails(
      bio: (json['bio'] as String? ?? '').trim(),
      gender: ProfileGender.fromValue(json['gender'] as String?),
      favoriteAccord: AccordCategories.byId(
        (json['favoriteAccordId'] ?? json['favoriteAccord']) as String?,
      ),
      signatureFragrance: signatureData is Map
          ? Parfum.fromJson(Map<String, dynamic>.from(signatureData))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bio': bio.trim(),
      'gender': gender?.value,
      'favoriteAccordId': favoriteAccord?.id,
      'signatureFragrance': signatureFragrance?.toJson(),
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'bio': bio.trim(),
      'gender': gender?.value,
      'favoriteAccord': favoriteAccord?.apiAccord,
      'signatureFragrance': signatureFragrance?.toProfileSignatureJson(),
    };
  }
}

const Object _sentinel = Object();
