import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/accord_category.dart';
import '../models/parfum.dart';
import '../models/profile_details.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/favorites_manager.dart';
import '../services/profile_preferences_service.dart';

class ProfileScreen extends StatefulWidget {
  final FavoritesManager favoritesManager;

  const ProfileScreen({super.key, required this.favoritesManager});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _bioMaxLength = 120;

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final ProfilePreferencesService _profileService = ProfilePreferencesService();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _signatureSearchController =
      TextEditingController();

  ProfileDetails _profile = const ProfileDetails.empty();
  ProfileGender? _selectedGender;
  AccordCategory? _selectedAccord;
  Parfum? _selectedSignatureFragrance;

  bool _isProfileLoading = true;
  bool _isEditingProfile = false;
  bool _isSavingProfile = false;
  bool _isSearchingFragrances = false;
  String? _profileErrorMessage;
  String? _signatureSearchError;
  List<Parfum> _signatureSearchResults = const [];

  Timer? _signatureSearchDebounce;
  int _latestSearchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _signatureSearchDebounce?.cancel();
    _bioController.dispose();
    _signatureSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isProfileLoading = false);
      return;
    }

    try {
      final profile = await _profileService.getProfile(user.uid);
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _hydrateDraft(profile);
        _isProfileLoading = false;
        _profileErrorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isProfileLoading = false;
        _profileErrorMessage = 'Could not load your profile details.';
      });
    }
  }

  void _hydrateDraft(ProfileDetails profile) {
    _bioController.text = profile.bio;
    _selectedGender = profile.gender;
    _selectedAccord = profile.favoriteAccord;
    _selectedSignatureFragrance = profile.signatureFragrance;
    _signatureSearchController.clear();
    _signatureSearchResults = const [];
    _isSearchingFragrances = false;
    _signatureSearchError = null;
    _signatureSearchDebounce?.cancel();
    _latestSearchRequestId++;
  }

  void _startEditing() {
    setState(() {
      _hydrateDraft(_profile);
      _isEditingProfile = true;
      _profileErrorMessage = null;
    });
  }

  void _cancelEditing() {
    FocusScope.of(context).unfocus();
    setState(() {
      _hydrateDraft(_profile);
      _isEditingProfile = false;
      _profileErrorMessage = null;
    });
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSavingProfile = true;
      _profileErrorMessage = null;
    });

    final nextProfile = ProfileDetails(
      bio: _bioController.text.trim(),
      gender: _selectedGender,
      favoriteAccord: _selectedAccord,
      signatureFragrance: _selectedSignatureFragrance,
    );

    try {
      final savedProfile = await _profileService.saveProfile(
        user.uid,
        nextProfile,
      );
      if (!mounted) return;

      setState(() {
        _profile = savedProfile;
        _hydrateDraft(savedProfile);
        _isEditingProfile = false;
        _isSavingProfile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSavingProfile = false;
        _profileErrorMessage = 'Could not save your profile right now.';
      });
    }
  }

  void _onSignatureQueryChanged(String value) {
    final query = value.trim();
    _signatureSearchDebounce?.cancel();
    final requestId = ++_latestSearchRequestId;

    if (query.length < 2) {
      setState(() {
        _isSearchingFragrances = false;
        _signatureSearchResults = const [];
        _signatureSearchError = null;
      });
      return;
    }

    _signatureSearchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _searchSignatureFragrances(query, requestId),
    );
  }

  Future<void> _searchSignatureFragrances(String query, int requestId) async {
    if (!mounted) return;

    setState(() {
      _isSearchingFragrances = true;
      _signatureSearchError = null;
    });

    try {
      final response = await _apiService.searchFragrances(query, limit: 8);
      final seenKeys = <String>{};
      final fragrances = response
          .map((item) => Parfum.fromJson(Map<String, dynamic>.from(item)))
          .where((parfum) => seenKeys.add(parfum.stableKey))
          .toList();

      if (!mounted || requestId != _latestSearchRequestId) return;

      setState(() {
        _isSearchingFragrances = false;
        _signatureSearchResults = fragrances;
      });
    } catch (_) {
      if (!mounted || requestId != _latestSearchRequestId) return;

      setState(() {
        _isSearchingFragrances = false;
        _signatureSearchResults = const [];
        _signatureSearchError = 'Could not search fragrances right now.';
      });
    }
  }

  void _selectSignatureFragrance(Parfum parfum) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedSignatureFragrance = parfum;
      _signatureSearchController.clear();
      _signatureSearchResults = const [];
      _signatureSearchError = null;
      _isSearchingFragrances = false;
      _signatureSearchDebounce?.cancel();
      _latestSearchRequestId++;
    });
  }

  void _clearSelectedSignatureFragrance() {
    setState(() {
      _selectedSignatureFragrance = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: widget.favoritesManager,
        builder: (context, _) {
          final favorites = widget.favoritesManager.favorites;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: _buildUserCard(user),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _buildProfileSection(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Favorites',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (favorites.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${favorites.length}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (favorites.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 48,
                          color: Colors.black.withValues(alpha: 0.12),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No favorites yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the heart on any fragrance to save it here',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final parfum = favorites[index];
                      return _FavoriteListItem(
                        parfum: parfum,
                        onRemove: () => widget.favoritesManager.remove(parfum),
                      );
                    }, childCount: favorites.length),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Log out'),
                            content: const Text(
                              'Are you sure you want to log out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text(
                                  'Log out',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await _authService.logout();
                        }
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Log out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserCard(User? user) {
    final bioText = _profile.hasBio
        ? _profile.bio
        : 'Add a short bio to tell your fragrance story.';

    return _SectionCard(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 44,
            backgroundColor: Colors.black87,
            child: Icon(Icons.person, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'Fragrance Lover',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              bioText,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: _profile.hasBio ? Colors.black87 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.black87),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customize profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your bio, personal preferences, and signature scent.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_profileErrorMessage != null) ...[
            _InlineMessage(message: _profileErrorMessage!, isError: true),
            const SizedBox(height: 16),
          ],
          if (_isProfileLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: Colors.black87),
              ),
            )
          else ...[
            Align(
              alignment: Alignment.centerRight,
              child: _isEditingProfile
                  ? Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        TextButton(
                          onPressed: _isSavingProfile ? null : _cancelEditing,
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isSavingProfile ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _isSavingProfile
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(_isSavingProfile ? 'Saving...' : 'Save'),
                        ),
                      ],
                    )
                  : OutlinedButton.icon(
                      onPressed: _startEditing,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _isEditingProfile
                  ? _buildEditableProfileContent()
                  : _buildReadOnlyProfileContent(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyProfileContent() {
    final signatureFragrance = _profile.signatureFragrance;

    return Column(
      key: const ValueKey('profile-readonly'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileSummaryTile(
          icon: Icons.person_outline_rounded,
          label: 'Gender',
          value: _profile.gender?.label ?? 'Not selected yet',
        ),
        const SizedBox(height: 12),
        _ProfileSummaryTile(
          icon: Icons.auto_awesome_outlined,
          label: 'Favorite accord',
          value: _profile.favoriteAccord?.label ?? 'Not selected yet',
          trailing: _profile.favoriteAccord == null
              ? null
              : _ProfileBadge(
                  leading: _profile.favoriteAccord!.icon,
                  label: _profile.favoriteAccord!.label,
                ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Signature Fragrance',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (signatureFragrance != null)
          _SelectedSignatureFragranceCard(parfum: signatureFragrance)
        else
          const _EmptyProfileHint(
            icon: Icons.local_florist_outlined,
            message:
                'Choose a signature fragrance to make your profile feel complete.',
          ),
      ],
    );
  }

  Widget _buildEditableProfileContent() {
    final currentQuery = _signatureSearchController.text.trim();
    final showNoResults =
        currentQuery.length >= 2 &&
        !_isSearchingFragrances &&
        _signatureSearchError == null &&
        _signatureSearchResults.isEmpty;

    return Column(
      key: const ValueKey('profile-editable'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _bioController,
          maxLength: _bioMaxLength,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            label: 'Bio',
            hint: 'Describe your fragrance taste in a few words.',
            prefixIcon: Icons.short_text_rounded,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final useVerticalLayout = constraints.maxWidth < 520;
            final fields = [
              Expanded(child: _buildGenderField()),
              Expanded(child: _buildFavoriteAccordField()),
            ];

            if (useVerticalLayout) {
              return Column(
                children: [
                  _buildGenderField(),
                  const SizedBox(height: 12),
                  _buildFavoriteAccordField(),
                ],
              );
            }

            return Row(
              children: [fields[0], const SizedBox(width: 12), fields[1]],
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Signature Fragrance',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Search for a perfume and pin one scent as your signature.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
        ),
        const SizedBox(height: 12),
        if (_selectedSignatureFragrance != null) ...[
          _SelectedSignatureFragranceCard(
            parfum: _selectedSignatureFragrance!,
            onClear: _clearSelectedSignatureFragrance,
            showSelectedBadge: true,
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _signatureSearchController,
          onChanged: _onSignatureQueryChanged,
          decoration: _inputDecoration(
            label: 'Search fragrance',
            hint: 'Start typing a perfume name...',
            prefixIcon: Icons.search_rounded,
          ),
        ),
        const SizedBox(height: 10),
        if (_isSearchingFragrances)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: CircularProgressIndicator(color: Colors.black87),
            ),
          )
        else if (_signatureSearchError != null)
          _InlineMessage(message: _signatureSearchError!, isError: true)
        else if (showNoResults)
          const _InlineMessage(
            message: 'No fragrances matched that search yet.',
          )
        else if (_signatureSearchResults.isNotEmpty)
          _SignatureSearchResults(
            results: _signatureSearchResults,
            onSelect: _selectSignatureFragrance,
          ),
      ],
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<ProfileGender>(
      initialValue: _selectedGender,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Gender',
        hint: 'Select gender',
        prefixIcon: Icons.person_outline_rounded,
      ),
      items: ProfileGender.values
          .map(
            (gender) => DropdownMenuItem<ProfileGender>(
              value: gender,
              child: Text(gender.label),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
    );
  }

  Widget _buildFavoriteAccordField() {
    return DropdownButtonFormField<AccordCategory>(
      initialValue: _selectedAccord,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Favorite accord',
        hint: 'Select accord',
        prefixIcon: Icons.auto_awesome_outlined,
      ),
      items: AccordCategories.all
          .map(
            (category) => DropdownMenuItem<AccordCategory>(
              value: category,
              child: Row(
                children: [
                  Text(category.icon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedAccord = value;
        });
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black87),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProfileSummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _ProfileSummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final String label;
  final String? leading;

  const _ProfileBadge({required this.label, this.leading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[Text(leading!), const SizedBox(width: 6)],
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SelectedSignatureFragranceCard extends StatelessWidget {
  final Parfum parfum;
  final VoidCallback? onClear;
  final bool showSelectedBadge;

  const _SelectedSignatureFragranceCard({
    required this.parfum,
    this.onClear,
    this.showSelectedBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final mainAccord = _extractPrimaryAccord(parfum.mainAccords);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 64,
              height: 64,
              child: parfum.imageUrl != null && parfum.imageUrl!.isNotEmpty
                  ? Image.network(
                      parfum.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _PerfumeImageFallback(),
                    )
                  : const _PerfumeImageFallback(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        parfum.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (showSelectedBadge)
                      const _ProfileBadge(label: 'Selected', leading: '✓'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  parfum.brand,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (mainAccord != null || parfum.year != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (mainAccord != null) _ProfileBadge(label: mainAccord),
                      if (parfum.year != null)
                        _ProfileBadge(label: parfum.year!),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Remove signature fragrance',
            ),
          ],
        ],
      ),
    );
  }
}

class _SignatureSearchResults extends StatelessWidget {
  final List<Parfum> results;
  final ValueChanged<Parfum> onSelect;

  const _SignatureSearchResults({
    required this.results,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: results.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
        itemBuilder: (context, index) {
          final parfum = results[index];
          return ListTile(
            onTap: () => onSelect(parfum),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 48,
                height: 48,
                child: parfum.imageUrl != null && parfum.imageUrl!.isNotEmpty
                    ? Image.network(
                        parfum.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _PerfumeImageFallback(),
                      )
                    : const _PerfumeImageFallback(),
              ),
            ),
            title: Text(
              parfum.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              parfum.brand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            trailing: const Icon(Icons.north_west_rounded, size: 18),
          );
        },
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _InlineMessage({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isError
        ? Colors.redAccent.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);
    final textColor = isError ? Colors.redAccent : Colors.black87;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyProfileHint extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyProfileHint({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfumeImageFallback extends StatelessWidget {
  const _PerfumeImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      alignment: Alignment.center,
      child: const Icon(Icons.water_drop_outlined, color: Colors.grey),
    );
  }
}

class _FavoriteListItem extends StatelessWidget {
  final Parfum parfum;
  final VoidCallback onRemove;

  const _FavoriteListItem({required this.parfum, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 52,
            height: 52,
            child: parfum.imageUrl != null && parfum.imageUrl!.isNotEmpty
                ? Image.network(
                    parfum.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.water_drop, color: Colors.grey),
                  )
                : const Icon(Icons.water_drop, color: Colors.grey),
          ),
        ),
        title: Text(
          parfum.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          parfum.brand,
          style: const TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
        trailing: GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.favorite, color: Colors.redAccent, size: 22),
        ),
      ),
    );
  }
}

String? _extractPrimaryAccord(String? accords) {
  if (accords == null || accords.trim().isEmpty) return null;

  final parts = accords.split(',');
  final first = parts.first.trim();
  return first.isEmpty ? null : first;
}
