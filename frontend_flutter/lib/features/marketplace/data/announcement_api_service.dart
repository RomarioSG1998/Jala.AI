import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AnnouncementModel {
  final String id;
  final String farmId;
  final String category; // ALEVINOS | RACAO | EQUIPAMENTOS
  final String title;
  final String description;
  final double price;
  final String sellerName;
  final String sellerPhone;
  final String sellerLocation;
  final String? imageUrl;
  final bool active;

  AnnouncementModel({
    required this.id,
    required this.farmId,
    required this.category,
    required this.title,
    required this.description,
    required this.price,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerLocation,
    this.imageUrl,
    required this.active,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> j) => AnnouncementModel(
        id: j['id']?.toString() ?? '',
        farmId: j['farmId']?.toString() ?? '',
        category: j['category'] ?? 'ALEVINOS',
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        price: (j['price'] ?? 0).toDouble(),
        sellerName: j['sellerName'] ?? '',
        sellerPhone: j['sellerPhone'] ?? '',
        sellerLocation: j['sellerLocation'] ?? '',
        imageUrl: j['imageUrl'],
        active: j['active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'farmId': farmId,
        'category': category,
        'title': title,
        'description': description,
        'price': price,
        'sellerName': sellerName,
        'sellerPhone': sellerPhone,
        'sellerLocation': sellerLocation,
        'imageUrl': imageUrl,
      };
}

class AnnouncementApiService {
  static const String _baseUrl = 'http://localhost:8080/api/announcements';
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AnnouncementApiService({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'auth_token');
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  Future<List<AnnouncementModel>> fetchAll({String? category, String? location}) async {
    final headers = await _headers();
    final Map<String, dynamic> params = {};
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (location != null && location.isNotEmpty) params['location'] = location;

    final response = await _dio.get(
      _baseUrl,
      queryParameters: params.isEmpty ? null : params,
      options: Options(headers: headers),
    );

    final list = response.data as List;
    return list.map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AnnouncementModel> create(AnnouncementModel model) async {
    final headers = await _headers();
    final response = await _dio.post(
      _baseUrl,
      data: model.toJson(),
      options: Options(headers: headers),
    );
    return AnnouncementModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deactivate(String id, String farmId) async {
    final headers = await _headers();
    await _dio.delete(
      '$_baseUrl/$id',
      queryParameters: {'farmId': farmId},
      options: Options(headers: headers),
    );
  }
}
