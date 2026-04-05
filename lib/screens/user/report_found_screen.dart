import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'report_form_widgets.dart';

class ReportFoundScreen extends StatefulWidget {
  const ReportFoundScreen({super.key});

  @override
  State<ReportFoundScreen> createState() => _ReportFoundScreenState();
}

class _ReportFoundScreenState extends State<ReportFoundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  File? _selectedImage;
  bool _isSubmitting = false;
  String? _selectedCategory;
  String? _storageOption;

  final List<String> _categories = const [
    'Electronics',
    'Bag / Backpack',
    'ID Card / Documents',
    'Keys',
    'Wallet / Purse',
    'Clothing',
    'Books / Notes',
    'Sports Equipment',
    'Other',
  ];

  final List<String> _storageOptions = const [
    'Submitted to Security Office',
    'Submitted to Reception',
    'Keeping with me',
    'Left at spot',
    'Submitted to Library',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                tileColor: AppTheme.canvas,
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                  if (image != null) setState(() => _selectedImage = File(image.path));
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                tileColor: AppTheme.canvas,
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                  if (image != null) setState(() => _selectedImage = File(image.path));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Photo is required for found items'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    if (_storageOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select where the item is stored'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = context.read<AuthProvider>().currentUser!;
      final photoURL = await _storageService.uploadFoundItemImage(_selectedImage!);
      if (photoURL == null) throw Exception('Image upload failed');

      await _firestoreService.reportFoundItem(
        finderId: user.uid,
        photoURL: photoURL,
        description: _descriptionCtrl.text.trim(),
        locationFound: _locationCtrl.text.trim(),
        storageOption: _storageOption!,
        category: _selectedCategory,
        finderName: user.name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Found item reported successfully'),
        backgroundColor: AppTheme.success,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppTheme.error,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.softGradient),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: ReportFormHeader(
                      title: 'Report found item',
                      subtitle: 'Give verifiers a clear record of what was found and where it is kept.',
                      badgeLabel: 'Found report',
                      badgeColor: AppTheme.success,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ReportUploadCard(
                        title: 'Required photo',
                        subtitle: 'A clear image helps verifiers match the right owner.',
                        icon: Icons.photo_camera_back_outlined,
                        imageFile: _selectedImage,
                        accent: AppTheme.success,
                        onTap: _pickImage,
                      ),
                      const SizedBox(height: 18),
                      ReportSectionCard(
                        title: 'Item details',
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                hintText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: _categories
                                  .map((category) =>
                                      DropdownMenuItem(value: category, child: Text(category)))
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedCategory = value),
                            ),
                            const SizedBox(height: 14),
                            AppTextField(
                              hint: 'Describe the item',
                              controller: _descriptionCtrl,
                              prefixIcon: Icons.description_outlined,
                              maxLines: 3,
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Description is required'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            AppTextField(
                              hint: 'Where did you find it?',
                              controller: _locationCtrl,
                              prefixIcon: Icons.location_on_outlined,
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Location is required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ReportSectionCard(
                        title: 'Storage status',
                        subtitle: 'Tell the owner and verifier where the item is currently kept.',
                        child: Column(
                          children: _storageOptions.map((option) {
                            final selected = _storageOption == option;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: selected ? AppTheme.primary.withOpacity(0.08) : AppTheme.canvas,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? AppTheme.primary : Colors.transparent,
                                ),
                              ),
                              child: RadioListTile<String>(
                                value: option,
                                groupValue: _storageOption,
                                activeColor: AppTheme.primary,
                                title: Text(option),
                                onChanged: (value) => setState(() => _storageOption = value),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 22),
                      AppButton(
                        text: 'Submit found report',
                        onPressed: _submit,
                        isLoading: _isSubmitting,
                        icon: Icons.send_rounded,
                        color: AppTheme.success,
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
