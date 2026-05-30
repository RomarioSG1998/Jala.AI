import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageNotifier extends Notifier<String?> {
  final String userId;
  ProfileImageNotifier(this.userId);

  @override
  String? build() {
    _loadProfileImage();
    return null;
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getString('profile_image_$userId');
    } catch (_) {
      // SharedPreferences might fail under web incognito/unsupported modes
    }
  }

  Future<void> pickAndSetImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_$userId', base64String);
        state = base64String;
      }
    } catch (_) {
      // Ignore pick exceptions
    }
  }

  Future<void> clearImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_$userId');
      state = null;
    } catch (_) {
      // Ignore remove exceptions
    }
  }
}

final profileImageProvider = NotifierProvider.family<ProfileImageNotifier, String?, String>(
  ProfileImageNotifier.new,
);
