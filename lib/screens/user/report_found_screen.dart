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
  final SpeechToText _speech = SpeechToText();

  File? _selectedImage;
  bool _isSubmitting = false;
  bool _speechReady = false;
  bool _isListening = false;
  String? _selectedCategory;
  String? _storageOption;
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

  final List<String> _storageOptions = const [
    'Submitted to Security Office',
    'Submitted to Reception',
    'Keeping with me',
    'Left at spot',
    'Submitted to Library',
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
              'Capture Found Item',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 20),
            _ImagePickTile(
              label: 'Take Photo',
              icon: Icons.camera_alt_rounded,
              color: AppTheme.success,
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
              color: AppTheme.success,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Photo is required for found items'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_storageOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please specify where item is kept'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Item successfully logged in system'),
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
                    title: 'Report Found Item',
                    subtitle: 'Accurate logging helps students retrieve their items faster.',
                    badgeLabel: 'Found Report',
                    badgeColor: AppTheme.success,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ReportUploadCard(
                      title: 'Item Photo',
                      subtitle: 'Mandatory. Ensure item is clearly visible.',
                      icon: Icons.photo_camera_back_rounded,
                      imageFile: _selectedImage,
                      accent: AppTheme.success,
                      onTap: _pickImage,
                    ),
                    const SizedBox(height: 24),
                    ReportSectionCard(
                      title: 'Identify Item',
                      child: Column(
                        children: [
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
                            hint: 'Describe what you found (colors, condition...)',
                            controller: _descriptionCtrl,
                            prefixIcon: Icons.description_rounded,
                            suffix: _voiceSuffix(_descriptionCtrl, 'description'),
                            maxLines: 3,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Description required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            hint: 'Where exactly was it found?',
                            controller: _locationCtrl,
                            prefixIcon: Icons.location_searching_rounded,
                            suffix: _voiceSuffix(_locationCtrl, 'location'),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Location required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ReportSectionCard(
                      title: 'Handling Status',
                      subtitle: 'Choose where the item is currently kept.',
                      child: Column(
                        children: _storageOptions.map((option) {
                          final selected = _storageOption == option;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => setState(() => _storageOption = option),
                              borderRadius: BorderRadius.circular(18),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: selected ? AppTheme.primary : AppTheme.border.withOpacity(0.5),
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          color: selected ? AppTheme.primary : AppTheme.textPrimary,
                                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      text: 'Submit Report',
                      onPressed: _submit,
                      isLoading: _isSubmitting,
                      icon: Icons.send_rounded,
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
