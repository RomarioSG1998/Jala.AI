import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageNotifier extends Notifier<String?> {
  final String userId;
  ProfileImageNotifier(this.userId);

  late final Dio _dio;

  @override
  String? build() {
    _dio = ref.watch(dioProvider);
    _loadProfileImage();
    return null;
  }

  Future<void> _loadProfileImage() async {
    // Fetch from backend database
    try {
      final response = await _dio.get('/api/auth/profile-image/$userId');
      if (response.statusCode == 200 && response.data != null) {
        final backendImg = response.data['profileImage'] as String?;
        if (backendImg != null && backendImg.isNotEmpty) {
          state = backendImg;
        }
      }
    } catch (_) {
      // Offline or backend connection issues, retain current in-memory state
    }
  }

  Future<void> pickAndSetImage() async {
    try {
      final picker = ImagePicker();
      // Optimize to 300x300 at 70% quality for avatar (~15-20KB base64 string)
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 70,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        
        state = base64String;

        // Save to backend database
        await _dio.put(
          '/api/auth/profile-image/$userId',
          data: {'profileImage': base64String},
        );
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint('ProfileImageNotifier.pickAndSetImage error: ${e.message} (status: ${e.response?.statusCode})');
      } else {
        debugPrint('ProfileImageNotifier.pickAndSetImage error: $e');
      }
    }
  }

  Future<void> clearImage() async {
    try {
      state = null;

      // Clear from backend database
      await _dio.put(
        '/api/auth/profile-image/$userId',
        data: {'profileImage': null},
      );
    } catch (e) {
      if (e is DioException) {
        debugPrint('ProfileImageNotifier.clearImage error: ${e.message} (status: ${e.response?.statusCode})');
      } else {
        debugPrint('ProfileImageNotifier.clearImage error: $e');
      }
    }
  }
}

final profileImageProvider = NotifierProvider.family<ProfileImageNotifier, String?, String>(
  ProfileImageNotifier.new,
);
