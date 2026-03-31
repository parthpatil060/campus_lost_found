import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

class StorageService {
  final Dio _dio = Dio();

  // Upload image to Cloudinary
  Future<String?> uploadImage({
    required File file,
    required String folder, // e.g. 'lost_items' or 'found_items'
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'upload_preset': AppConstants.cloudinaryUploadPreset,
        'folder': 'campus_lost_found/$folder',
      });

      final response = await _dio.post(
        AppConstants.cloudinaryBaseUrl,
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String;
      }
      return null;
    } on DioException catch (e) {
      throw Exception('Image upload failed: ${e.message}');
    }
  }

  Future<String?> uploadLostItemImage(File file) async {
    return uploadImage(file: file, folder: 'lost_items');
  }

  Future<String?> uploadFoundItemImage(File file) async {
    return uploadImage(file: file, folder: 'found_items');
  }
}
