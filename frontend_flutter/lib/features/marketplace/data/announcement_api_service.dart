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
  final int stockQuantity;
  final String unitMeasure;
  final int minOrderQuantity;
  final String? deliveryTerms;
  final String? specifications;
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
    this.stockQuantity = 100,
    this.unitMeasure = 'Unidade',
    this.minOrderQuantity = 1,
    this.deliveryTerms,
    this.specifications,
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
        stockQuantity: (j['stockQuantity'] as num?)?.toInt() ?? 100,
        unitMeasure: j['unitMeasure']?.toString() ?? 'Unidade',
        minOrderQuantity: (j['minOrderQuantity'] as num?)?.toInt() ?? 1,
        deliveryTerms: j['deliveryTerms']?.toString(),
        specifications: j['specifications']?.toString(),
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
        'stockQuantity': stockQuantity,
        'unitMeasure': unitMeasure,
        'minOrderQuantity': minOrderQuantity,
        'deliveryTerms': deliveryTerms,
        'specifications': specifications,
      };
}

class AnnouncementApiService {
  final Dio _dio;

  AnnouncementApiService({required Dio dio}) : _dio = dio;

  Future<List<AnnouncementModel>> fetchAll({String? category, String? location}) async {
    final Map<String, dynamic> params = {};
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (location != null && location.isNotEmpty) params['location'] = location;

    final response = await _dio.get(
      '/api/announcements',
      queryParameters: params.isEmpty ? null : params,
    );

    final list = response.data as List;
    return list.map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AnnouncementModel> create(AnnouncementModel model) async {
    final response = await _dio.post(
      '/api/announcements',
      data: model.toJson(),
    );
    return AnnouncementModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deactivate(String id, String farmId) async {
    await _dio.delete(
      '/api/announcements/$id',
      queryParameters: {'farmId': farmId},
    );
  }
}
