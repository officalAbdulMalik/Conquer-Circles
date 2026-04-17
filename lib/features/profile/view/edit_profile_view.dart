import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_spacing.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/services/supabase_service.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  static const _displayNameKeys = ['display_name', 'full_name', 'name'];
  static const _locationKeys = ['location', 'city', 'region'];
  static const _birthdayKeys = ['birth_date', 'birthday', 'date_of_birth'];
  static const _bioKeys = ['bio', 'about', 'about_me'];
  static const _heightKeys = ['height_cm', 'height'];
  static const _weightKeys = ['weight_kg', 'weight'];

  final _service = SupabaseService();
  final _picker = ImagePicker();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _bioController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  final Set<String> _profileKeys = <String>{};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _avatarUrl;
  Uint8List? _selectedAvatarBytes;
  String _selectedAvatarExt = 'jpg';
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _birthdayController.dispose();
    _bioController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _service.getProfile() ?? <String, dynamic>{};
      _profileKeys
        ..clear()
        ..addAll(profile.keys.map((e) => e.toString()));

      _avatarUrl = profile['avatar_url']?.toString();
      _displayNameController.text = _readText(profile, _displayNameKeys);
      _usernameController.text =
          profile['username']?.toString() ??
          _service.currentUser?.email?.split('@').first ??
          '';
      _emailController.text = _service.currentUser?.email ?? '';
      _locationController.text = _readText(profile, _locationKeys);
      _bioController.text = _readText(profile, _bioKeys);
      _heightController.text = _readText(profile, _heightKeys);
      _weightController.text = _readText(profile, _weightKeys);

      final birthdayRaw = _readText(profile, _birthdayKeys);
      if (birthdayRaw.isNotEmpty) {
        final parsed = DateTime.tryParse(birthdayRaw);
        if (parsed != null) {
          _selectedBirthDate = parsed;
          _birthdayController.text = _formatDate(parsed);
        } else {
          _birthdayController.text = birthdayRaw;
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _readText(Map<String, dynamic> profile, List<String> keys) {
    for (final key in keys) {
      final value = profile[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  String? _existingKey(List<String> keys) {
    for (final key in keys) {
      if (_profileKeys.contains(key)) return key;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final dot = file.name.lastIndexOf('.');
      final ext = dot >= 0 ? file.name.substring(dot + 1) : 'jpg';
      if (!mounted) return;
      setState(() {
        _selectedAvatarBytes = bytes;
        _selectedAvatarExt = ext.toLowerCase();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take a photo'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.brandPurple),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthdayController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username is required')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      var avatarUrl = _avatarUrl;
      if (_selectedAvatarBytes != null) {
        avatarUrl = await _service.uploadProfileAvatar(
          _selectedAvatarBytes!,
          fileExtension: _selectedAvatarExt,
        );
      }

      final updates = <String, dynamic>{'username': username};

      if (_profileKeys.contains('avatar_url') && avatarUrl != null) {
        updates['avatar_url'] = avatarUrl;
      }

      final displayNameKey = _existingKey(_displayNameKeys);
      if (displayNameKey != null) {
        final value = _displayNameController.text.trim();
        updates[displayNameKey] = value.isEmpty ? null : value;
      }

      final locationKey = _existingKey(_locationKeys);
      if (locationKey != null) {
        final value = _locationController.text.trim();
        updates[locationKey] = value.isEmpty ? null : value;
      }

      final bioKey = _existingKey(_bioKeys);
      if (bioKey != null) {
        final value = _bioController.text.trim();
        updates[bioKey] = value.isEmpty ? null : value;
      }

      final birthdayKey = _existingKey(_birthdayKeys);
      if (birthdayKey != null) {
        updates[birthdayKey] = _selectedBirthDate
            ?.toIso8601String()
            .split('T')
            .first;
      }

      final heightKey = _existingKey(_heightKeys);
      if (heightKey != null) {
        final value = _heightController.text.trim();
        updates[heightKey] = value.isEmpty ? null : num.tryParse(value);
      }

      final weightKey = _existingKey(_weightKeys);
      if (weightKey != null) {
        final value = _weightController.text.trim();
        updates[weightKey] = value.isEmpty ? null : num.tryParse(value);
      }

      await _service.updateProfile(updates);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _Header(
                    onBack: () => Navigator.of(context).pop(),
                    avatarUrl: _avatarUrl,
                    selectedAvatarBytes: _selectedAvatarBytes,
                    onAvatarTap: _showImageSourceSheet,
                  ),
                  Padding(
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionCard(
                          title: 'Personal Info',
                          child: Column(
                            children: [
                              _FieldBlock(
                                label: 'Display Name',
                                icon: Icons.person_2_outlined,
                                controller: _displayNameController,
                                hint: 'Your display name',
                              ),
                              _FieldBlock(
                                label: 'Username',
                                icon: Icons.alternate_email,
                                controller: _usernameController,
                                hint: 'username',
                              ),
                              _FieldBlock(
                                label: 'Email',
                                icon: Icons.mail_outline_rounded,
                                controller: _emailController,
                                hint: 'Email',
                                readOnly: true,
                              ),
                              _FieldBlock(
                                label: 'Location',
                                icon: Icons.location_on_outlined,
                                controller: _locationController,
                                hint: 'City / Region',
                              ),
                              _FieldBlock(
                                label: 'Birthday',
                                icon: Icons.calendar_today_outlined,
                                controller: _birthdayController,
                                hint: 'YYYY-MM-DD',
                                readOnly: true,
                                onTap: _pickBirthDate,
                              ),
                              _FieldBlock(
                                label: 'Bio',
                                icon: Icons.person_outline_rounded,
                                controller: _bioController,
                                hint: 'Tell us about your fitness journey...',
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                        12.verticalSpace,
                        _SectionCard(
                          title: 'Body Metrics',
                          child: Row(
                            children: [
                              Expanded(
                                child: _FieldBlock(
                                  label: 'Height (cm)',
                                  icon: Icons.straighten_rounded,
                                  controller: _heightController,
                                  hint: '175',
                                  keyboardType: TextInputType.number,
                                  isTight: true,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _FieldBlock(
                                  label: 'Weight (kg)',
                                  icon: Icons.fitness_center_outlined,
                                  controller: _weightController,
                                  hint: '72',
                                  keyboardType: TextInputType.number,
                                  isTight: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        18.verticalSpace,
                        SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            icon: _isSaving
                                ? SizedBox(
                                    height: 18.r,
                                    width: 18.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.surface,
                                    ),
                                  )
                                : Icon(
                                    Icons.save_alt_outlined,
                                    size: 18.sp,
                                    color: AppColors.surface,
                                  ),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save Changes',
                              style: AppTextStyles.poppins(
                                size: 16,
                                color: AppColors.surface,
                                weight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.brandPurple,
                              foregroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                          ),
                        ),
                        24.verticalSpace,
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.avatarUrl,
    required this.selectedAvatarBytes,
    required this.onAvatarTap,
  });

  final VoidCallback onBack;
  final String? avatarUrl;
  final Uint8List? selectedAvatarBytes;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandPurple, AppColors.brandCyan],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 58.h,
            left: 14.w,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface.withValues(alpha: 0.18),
              ),
              child: IconButton(
                onPressed: onBack,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.surface,
                  size: 16.sp,
                ),
              ),
            ),
          ),
          Positioned(
            top: 60.h,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Edit Profile',
                style: AppTextStyles.poppins(
                  size: 22,
                  color: AppColors.surface,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -44.h,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onAvatarTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 98.w,
                      height: 98.w,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textNavy.withValues(alpha: 0.18),
                            blurRadius: 16.r,
                            offset: Offset(0, 5.h),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: _AvatarContent(
                          avatarUrl: avatarUrl,
                          selectedAvatarBytes: selectedAvatarBytes,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2.w,
                      bottom: -2.h,
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: AppColors.brandPurple,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2.w,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 16.sp,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarContent extends StatelessWidget {
  const _AvatarContent({
    required this.avatarUrl,
    required this.selectedAvatarBytes,
  });

  final String? avatarUrl;
  final Uint8List? selectedAvatarBytes;

  @override
  Widget build(BuildContext context) {
    if (selectedAvatarBytes != null) {
      return Image.memory(selectedAvatarBytes!, fit: BoxFit.cover);
    }
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Icon(
      Icons.account_circle_outlined,
      size: 48.sp,
      color: AppColors.textSecondary,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.poppins(
              size: 18,
              color: AppColors.textNavy,
              weight: FontWeight.w700,
            ),
          ),
          10.verticalSpace,
          child,
        ],
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.icon,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.isTight = false,
    this.readOnly = false,
    this.keyboardType,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool isTight;
  final bool readOnly;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final minLines = maxLines > 1 ? 3 : 1;
    return Padding(
      padding: EdgeInsets.only(bottom: isTight ? 0 : 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.sp, color: AppColors.brandPurple),
              6.horizontalSpace,
              Text(
                label,
                style: AppTextStyles.poppins(
                  size: 12,
                  color: AppColors.brandPurple,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          6.verticalSpace,
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            readOnly: readOnly,
            keyboardType: keyboardType,
            onTap: onTap,
            style: AppTextStyles.poppins(
              size: 14,
              color: AppColors.textNavy,
              weight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.poppins(
                size: 14,
                color: AppColors.textSecondary,
                weight: FontWeight.w500,
              ),
              filled: true,
              fillColor: AppColors.fillColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppColors.brandPurple.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
