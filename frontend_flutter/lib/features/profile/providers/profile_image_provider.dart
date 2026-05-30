import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // 1. Try to load from local cache first for instant UI response
    try {
      final prefs = await SharedPreferences.getInstance();
      final localImg = prefs.getString('profile_image_$userId');
      if (localImg != null) {
        state = localImg;
      }
    } catch (_) {}

    // 2. Fetch from backend database to sync/update cache
    try {
      final response = await _dio.get('/api/auth/profile-image/$userId');
      if (response.statusCode == 200 && response.data != null) {
        final backendImg = response.data['profileImage'] as String?;
        
        final prefs = await SharedPreferences.getInstance();
        if (backendImg != null && backendImg.isNotEmpty) {
          if (backendImg != state) {
            state = backendImg;
            await prefs.setString('profile_image_$userId', backendImg);
          }
        } else {
          // If backend has no image but we had one locally, clear local (e.g. deleted from another session)
          if (state != null) {
            state = null;
            await prefs.remove('profile_image_$userId');
          }
        }
      }
    } catch (_) {
      // Offline or backend connection issues, retain local state
    }
  }

  Future<void> pickAndSetImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final base64String = base64Encode(bytes);
        
        // Save to local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_$userId', base64String);
        state = base64String;

        // Save to backend database
        await _dio.put(
          '/api/auth/profile-image/$userId',
          data: {'profileImage': base64String},
        );
      }
    } catch (e, stack) {
      print('ProfileImageNotifier.pickAndSetImage error: $e\n$stack');
    }
  }

  Future<void> clearImage() async {
    try {
      // Clear from local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_$userId');
      state = null;

      // Clear from backend database
      await _dio.put(
        '/api/auth/profile-image/$userId',
        data: {'profileImage': null},
      );
    } catch (_) {
      // Ignore remove or network exceptions
    }
  }
}

final profileImageProvider = NotifierProvider.family<ProfileImageNotifier, String?, String>(
  ProfileImageNotifier.new,
);
