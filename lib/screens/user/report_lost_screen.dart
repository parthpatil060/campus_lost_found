import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'report_form_widgets.dart';

class ReportLostScreen extends StatefulWidget {
  const ReportLostScreen({super.key});

  @override
  State<ReportLostScreen> createState() => _ReportLostScreenState();
}

class _ReportLostScreenState extends State<ReportLostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameCtrl = TextEditingController();
  final _secretDetailCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _locations = <String>[];
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _picker = ImagePicker();
  final SpeechToText _speech = SpeechToText();

  File? _selectedImage;
  bool _isSubmitting = false;
  bool _speechReady = false;
  bool _isListening = false;
  String? _selectedCategory;
  String? _activeVoiceField;

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

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _speech.stop();
    _itemNameCtrl.dispose();
    _secretDetailCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
            _activeVoiceField = null;
          });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _activeVoiceField = null;
        });
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleVoiceInput(
    TextEditingController controller,
    String fieldName,
  ) async {
    if (!_speechReady) {
      await _initSpeech();
    }
    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Voice input unavailable'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (_isListening && _activeVoiceField == fieldName) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          _activeVoiceField = null;
        });
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
    }

    if (mounted) {
      setState(() {
        _isListening = true;
        _activeVoiceField = fieldName;
      });
    }

    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isEmpty) return;
        controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        if (result.finalResult && mounted) {
          setState(() {
            _isListening = false;
            _activeVoiceField = null;
          });
        }
      },
      partialResults: true,
      cancelOnError: true,
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 5),
    );
  }

  Widget _voiceSuffix(TextEditingController controller, String fieldName) {
    final isActive = _isListening && _activeVoiceField == fieldName;
    return IconButton(
      tooltip: isActive ? 'Stop' : 'Voice Input',
      icon: Icon(
        isActive ? Icons.mic_rounded : Icons.mic_none_rounded,
        color: isActive ? AppTheme.accent : AppTheme.textSecondary,
      ),
      onPressed: () => _toggleVoiceInput(controller, fieldName),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.border.withOpacity(0.5),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Item Photo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 20),
            _ImagePickTile(
              label: 'Take Photo',
              icon: Icons.camera_alt_rounded,
              color: AppTheme.primary,
              onTap: () async {
                Navigator.pop(context);
                final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (image != null) setState(() => _selectedImage = File(image.path));
              },
            ),
            const SizedBox(height: 12),
            _ImagePickTile(
              label: 'Choose from Gallery',
              icon: Icons.photo_library_rounded,
              color: AppTheme.primary,
              onTap: () async {
                Navigator.pop(context);
                final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (image != null) setState(() => _selectedImage = File(image.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addLocation() {
    final location = _locationCtrl.text.trim();
    if (location.isEmpty) return;
    setState(() {
      _locations.add(location);
      _locationCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Add at least one possible location'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userId = context.read<AuthProvider>().currentUser!.uid;
      String? photoURL;
      if (_selectedImage != null) {
        photoURL = await _storageService.uploadLostItemImage(_selectedImage!);
      }

      await _firestoreService.reportLostItem(
        userId: userId,
        itemName: _itemNameCtrl.text.trim(),
        secretIdentificationDetail: _secretDetailCtrl.text.trim(),
        possibleLocations: _locations,
        photoURL: photoURL,
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        category: _selectedCategory,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Item reported successfully'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: ReportFormHeader(
                    title: 'Report Lost Item',
                    subtitle: 'Help verifiers find your item by providing precise details.',
                    badgeLabel: 'Lost Report',
                    badgeColor: AppTheme.error,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ReportUploadCard(
                      title: 'Item Snapshot',
                      subtitle: 'Highly recommended for faster matches.',
                      icon: Icons.add_photo_alternate_rounded,
                      imageFile: _selectedImage,
                      accent: AppTheme.error,
                      onTap: _pickImage,
                    ),
                    const SizedBox(height: 24),
                    ReportSectionCard(
                      title: 'Key Information',
                      child: Column(
                        children: [
                          AppTextField(
                            hint: 'What did you lose?',
                            controller: _itemNameCtrl,
                            prefixIcon: Icons.inventory_2_rounded,
                            suffix: _voiceSuffix(_itemNameCtrl, 'item_name'),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Item name required' : null,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              isDense: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                prefixIcon: Icon(Icons.category_rounded, size: 20),
                                prefixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 44),
                                hintText: 'Select Category',
                              ),
                              items: _categories
                                  .map((category) =>
                                      DropdownMenuItem(value: category, child: Text(category)))
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedCategory = value),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            hint: 'Additional description (color, brand...)',
                            controller: _descriptionCtrl,
                            prefixIcon: Icons.description_rounded,
                            suffix: _voiceSuffix(_descriptionCtrl, 'description'),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ReportSectionCard(
                      title: 'Ownership Proof',
                      subtitle: 'Confidential details only you know (marks, serials, stickers).',
                      child: AppTextField(
                        hint: 'Example: Green sticker on back, Cracked screen top left',
                        controller: _secretDetailCtrl,
                        prefixIcon: Icons.verified_user_rounded,
                        suffix: _voiceSuffix(_secretDetailCtrl, 'secret_detail'),
                        maxLines: 2,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Secret detail required'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ReportSectionCard(
                      title: 'Last Seen Locations',
                      subtitle: 'Add campus areas where you may have lost the item.',
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      hint: 'Library, Lab 4, Canteen...',
                                      controller: _locationCtrl,
                                      prefixIcon: Icons.my_location_rounded,
                                      suffix: _voiceSuffix(_locationCtrl, 'location'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton.filled(
                                    onPressed: _addLocation,
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      fixedSize: const Size(54, 54),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add_rounded),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (_locations.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _locations.map((location) {
                                return Chip(
                                  label: Text(location, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                  onDeleted: () => setState(() => _locations.remove(location)),
                                  deleteIcon: const Icon(Icons.close_rounded, size: 14),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      text: 'Confirm & Report',
                      onPressed: _submit,
                      isLoading: _isSubmitting,
                      icon: Icons.check_circle_rounded,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ImagePickTile({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      tileColor: AppTheme.background,
    );
  }
}
