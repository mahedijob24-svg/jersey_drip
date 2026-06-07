import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/user_profile.dart';
import 'services/profile_service.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_text_field.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
    _addressController = TextEditingController(text: widget.profile.address);
    _cityController = TextEditingController(text: widget.profile.city);
    _postalCodeController = TextEditingController(
      text: widget.profile.postalCode,
    );
    _countryController = TextEditingController(text: widget.profile.country);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
    });

    try {
      await _profileService.updateCurrentUserProfile(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        city: _cityController.text,
        postalCode: _postalCodeController.text,
        country: _countryController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to update profile')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String? _requiredText(String? value, String fieldName) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter $fieldName.';
    if (text.length > 120) return 'Please enter a shorter $fieldName.';
    return null;
  }

  String? _phoneValidator(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Please enter your phone number.';
    if (!RegExp(r'^[0-9+\-\s()]{7,20}$').hasMatch(phone)) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  String? _postalCodeValidator(String? value) {
    final postalCode = value?.trim() ?? '';
    if (postalCode.isEmpty) return 'Please enter postal code.';
    if (!RegExp(r'^[A-Za-z0-9\-\s]{3,20}$').hasMatch(postalCode)) {
      return 'Please enter a valid postal code.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.backgroundDark,
        title: Text(
          'Edit Profile',
          style: AppTextStyles.label.copyWith(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Account Email',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.profile.email,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.backgroundDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthTextField(
                      controller: _nameController,
                      label: 'Name',
                      validator: (value) => _requiredText(value, 'your name'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: _phoneValidator,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthTextField(
                      controller: _addressController,
                      label: 'Address',
                      validator: (value) => _requiredText(value, 'address'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthTextField(
                      controller: _cityController,
                      label: 'City',
                      validator: (value) => _requiredText(value, 'city'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthTextField(
                      controller: _postalCodeController,
                      label: 'Postal Code',
                      keyboardType: TextInputType.text,
                      validator: _postalCodeValidator,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthTextField(
                      controller: _countryController,
                      label: 'Country',
                      validator: (value) => _requiredText(value, 'country'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AuthButton(
                      label: 'Save Changes',
                      onPressed: _save,
                      isLoading: _saving,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
