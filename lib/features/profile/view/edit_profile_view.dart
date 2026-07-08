import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/providers/edit_profile_provider.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';
import 'package:test_steps/widgets/shared/dashboard_segmented_tab_bar.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

/// Pure view: profile loading, mapping, avatar upload and saving live in
/// [EditProfileNotifier]. This state only owns text controllers and the
/// image-picker plumbing (platform UI, not business logic).
class _EditProfileViewState extends ConsumerState<EditProfileView> {
  final _picker = ImagePicker();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _bioController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _weightGoalController = TextEditingController();
  final _dailyGoalController = TextEditingController();

  bool _controllersSeeded = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _birthdayController.dispose();
    _bioController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _weightGoalController.dispose();
    _dailyGoalController.dispose();
    super.dispose();
  }

  void _seedControllers(EditProfileFormData form) {
    if (_controllersSeeded) return;
    _controllersSeeded = true;
    _displayNameController.text = form.displayName;
    _usernameController.text = form.username;
    _emailController.text = form.email;
    _ageController.text = form.age;
    _locationController.text = form.location;
    _birthdayController.text = form.birthday;
    _bioController.text = form.bio;
    _heightController.text = form.height;
    _weightController.text = form.weight;
    _weightGoalController.text = form.weightGoal;
    _dailyGoalController.text = form.dailyGoal;
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
      ref.read(editProfileProvider.notifier).setAvatar(bytes, ext);
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

  void _saveProfile() {
    ref.read(editProfileProvider.notifier).save(
          displayNameText: _displayNameController.text,
          usernameText: _usernameController.text,
          ageText: _ageController.text,
          locationText: _locationController.text,
          bioText: _bioController.text,
          heightText: _heightController.text,
          weightText: _weightController.text,
          weightGoalText: _weightGoalController.text,
          dailyGoalText: _dailyGoalController.text,
        );
  }

  int _numericValue(String text, {required int fallback}) {
    final match = RegExp(r'\d+').stringMatch(text);
    return int.tryParse(match ?? '') ?? fallback;
  }

  Future<void> _pickBirthday() async {
    final notifier = ref.read(editProfileProvider.notifier);
    final current = ref.read(editProfileProvider).form?.birthDate;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    notifier.setBirthDate(picked);
    final mm = picked.month.toString().padLeft(2, '0');
    final dd = picked.day.toString().padLeft(2, '0');
    _birthdayController.text = '${picked.year}-$mm-$dd';
    _ageController.text = '${notifier.ageForBirthDate(picked)}y';
  }

  Future<void> _pickHeight() async {
    final value = await _showNumberPicker(
      title: 'Height',
      unit: 'cm',
      min: 120,
      max: 220,
      initial: _numericValue(_heightController.text, fallback: 170),
    );
    if (value != null) _heightController.text = '$value cm';
  }

  Future<void> _pickWeight() async {
    final value = await _showNumberPicker(
      title: 'Weight',
      unit: 'kg',
      min: 30,
      max: 250,
      initial: _numericValue(_weightController.text, fallback: 70),
    );
    if (value != null) _weightController.text = '$value kg';
  }

  Future<int?> _showNumberPicker({
    required String title,
    required String unit,
    required int min,
    required int max,
    required int initial,
  }) {
    var selected = initial.clamp(min, max).toInt();
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: 300.h,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.montserrat(
                          size: 16.sp,
                          weight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(selected),
                        child: Text(
                          'Done',
                          style: AppTextStyles.montserrat(
                            size: 15.sp,
                            weight: FontWeight.w700,
                            color: AppColors.blueColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: selected - min,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) => selected = min + index,
                    children: [
                      for (var v = min; v <= max; v++)
                        Center(
                          child: Text(
                            '$v $unit',
                            style: AppTextStyles.montserrat(
                              size: 18.sp,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(editProfileProvider);
    final form = profileState.form;
    if (form != null) _seedControllers(form);

    // One-shot side effects: feedback snackbars and pop-on-save.
    ref.listen<EditProfileState>(editProfileProvider, (previous, next) {
      final message = next.message;
      if (message != null && previous?.message != message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      if (next.saved && previous?.saved != true) {
        Navigator.of(context).pop(true);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
           AppBackgroundImage(height: 250.sp, color: AppColors.surface.withValues(alpha: 0.72),
          ),
          SafeArea(
            child: profileState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 34.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EditProfileHeader(
                          onAvatarTap: _showImageSourceSheet,
                          avatarUrl: form?.avatarUrl,
                          selectedAvatarBytes: profileState.selectedAvatarBytes,
                        ),
                        0.verticalSpace,
                        AppTextInput(
                          controller: _displayNameController,
                          hintText: 'Name',
                          height: 49,
                        ),
                        18.verticalSpace,
                        AppTextInput(
                          controller: _emailController,
                          hintText: 'Email',
                          readOnly: true,
                          keyboardType: TextInputType.emailAddress,
                          height: 49,
                        ),
                        18.verticalSpace,
                        DashboardSegmentedTabBar(
                          labels: const ['Male', 'Female'],
                          selectedIndex:
                              profileState.selectedGender == 'Female' ? 1 : 0,
                          height: 43,
                          backgroundColor: AppColors.surface,
                          inactiveTextColor: AppColors.textNavy,
                          onChanged: (index) => ref
                              .read(editProfileProvider.notifier)
                              .setGender(index == 1 ? 'Female' : 'Male'),
                        ),
                        18.verticalSpace,
                        AppTextInput(
                          controller: _ageController,
                          hintText: 'Age',
                          keyboardType: TextInputType.number,
                          height: 49,
                        ),
                        18.verticalSpace,
                        AppTextInput(
                          controller: _birthdayController,
                          hintText: 'Birthday',
                          readOnly: true,
                          height: 49,
                          onTap: _pickBirthday,
                          suffixIcon: Icon(
                            Icons.calendar_today_outlined,
                            size: 18.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        18.verticalSpace,
                        Row(
                          children: [
                            Expanded(
                              child: AppTextInput(
                                controller: _weightController,
                                hintText: 'Weight',
                                readOnly: true,
                                onTap: _pickWeight,
                                height: 49,
                                suffixIcon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            18.horizontalSpace,
                            Expanded(
                              child: AppTextInput(
                                controller: _heightController,
                                hintText: 'Height',
                                readOnly: true,
                                onTap: _pickHeight,
                                height: 49,
                                suffixIcon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        18.verticalSpace,
                        AppTextInput(
                          controller: _weightGoalController,
                          hintText: 'Goal',
                          height: 49,
                          readOnly: true,
                        ),
                        18.verticalSpace,
                        AppTextInput(
                          controller: _dailyGoalController,
                          hintText: 'Daily Goal',
                          readOnly: true,
                          keyboardType: TextInputType.number,
                          height: 49,
                        ),
                        46.verticalSpace,
                        PrimaryButton(
                          label: profileState.isSaving ? 'Saving...' : 'Save',
                          isLoading: profileState.isSaving,
                          onTap: profileState.isSaving ? null : _saveProfile,
                          verticalPadding: 15.h,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileHeader extends StatelessWidget {
  const _EditProfileHeader({
    required this.avatarUrl,
    required this.selectedAvatarBytes,
    required this.onAvatarTap,
  });

  final String? avatarUrl;
  final Uint8List? selectedAvatarBytes;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 221.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(top: 0, left: 0, child: AppCircularBackButton()),
          Positioned(
            top: 9.h,
            left: 0,
            right: 0,
            child: Text(
              'Edit profile',
              textAlign: TextAlign.center,
              style: AppTextStyles.montserrat(
                size: 20.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            top: 72.h,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onAvatarTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 110.w,
                      height: 110.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: ClipOval(
                        child: _AvatarContent(
                          avatarUrl: avatarUrl,
                          selectedAvatarBytes: selectedAvatarBytes,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2.w,
                      bottom: 3.h,
                      child: Container(
                        width: 34.w,
                        height: 34.w,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 10.r,
                              offset: Offset(0, 3.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.manage_accounts_outlined,
                          size: 20.sp,
                          color: AppColors.textPrimary,
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
    return Image.asset(
      'assets/images/profile.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(
        Icons.account_circle_outlined,
        size: 58.sp,
        color: AppColors.textSecondary,
      ),
    );
  }
}
