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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Voice input is not available on this device right now'),
        backgroundColor: AppTheme.error,
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
      tooltip: isActive ? 'Stop voice input' : 'Start voice input',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: AppTheme.canvas,
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );
                  if (image != null) setState(() => _selectedImage = File(image.path));
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: AppTheme.canvas,
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  if (image != null) setState(() => _selectedImage = File(image.path));
                },
              ),
            ],
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least one possible location'),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lost item reported successfully'),
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
                      title: 'Report lost item',
                      subtitle: 'Add strong details so verifiers can confirm ownership faster.',
                      badgeLabel: 'Lost report',
                      badgeColor: AppTheme.error,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ReportUploadCard(
                        title: 'Item photo',
                        subtitle: 'Optional, but helpful for faster matching.',
                        icon: Icons.add_photo_alternate_outlined,
                        imageFile: _selectedImage,
                        accent: AppTheme.error,
                        onTap: _pickImage,
                      ),
                      const SizedBox(height: 18),
                      ReportSectionCard(
                        title: 'Item details',
                        child: Column(
                          children: [
                            AppTextField(
                              hint: 'Item name',
                              controller: _itemNameCtrl,
                              prefixIcon: Icons.inventory_2_outlined,
                              suffix: _voiceSuffix(_itemNameCtrl, 'item_name'),
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Item name is required' : null,
                            ),
                            const SizedBox(height: 14),
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
                              hint: 'Description',
                              controller: _descriptionCtrl,
                              prefixIcon: Icons.notes_rounded,
                              suffix: _voiceSuffix(_descriptionCtrl, 'description'),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ReportSectionCard(
                        title: 'Verification detail',
                        subtitle:
                            'This stays confidential and helps confirm the real owner later.',
                        child: AppTextField(
                          hint: 'Example: serial number, sticker, handwritten mark',
                          controller: _secretDetailCtrl,
                          prefixIcon: Icons.lock_outline_rounded,
                          suffix: _voiceSuffix(_secretDetailCtrl, 'secret_detail'),
                          maxLines: 2,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Secret detail is required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ReportSectionCard(
                        title: 'Possible locations',
                        subtitle: 'Add a few places where you may have left the item.',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    hint: 'Library, canteen, classroom, lab',
                                    controller: _locationCtrl,
                                    prefixIcon: Icons.location_on_outlined,
                                    suffix: _voiceSuffix(_locationCtrl, 'location'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton.filled(
                                  onPressed: _addLocation,
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    fixedSize: const Size(52, 52),
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                ),
                              ],
                            ),
                            if (_locations.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _locations.map((location) {
                                  return Chip(
                                    label: Text(location),
                                    onDeleted: () => setState(() => _locations.remove(location)),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      AppButton(
                        text: 'Submit lost report',
                        onPressed: _submit,
                        isLoading: _isSubmitting,
                        icon: Icons.send_rounded,
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
