import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_flutter/features/weather/data/weather_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Estado
// ──────────────────────────────────────────────────────────────────────────────
class WeatherState {
  final WeatherForecast? forecast;
  final bool isLoading;
  final String? error;
  final double latitude;
  final double longitude;
  final String cityName;
  final bool locationGranted;

  const WeatherState({
    this.forecast,
    this.isLoading = false,
    this.error,
    this.latitude = -9.3984,
    this.longitude = -40.5018,
    this.cityName = 'Petrolina, PE',
    this.locationGranted = false,
  });

  WeatherState copyWith({
    WeatherForecast? forecast,
    bool? isLoading,
    String? error,
    double? latitude,
    double? longitude,
    String? cityName,
    bool? locationGranted,
  }) {
    return WeatherState(
      forecast: forecast ?? this.forecast,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      locationGranted: locationGranted ?? this.locationGranted,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Notifier
// ──────────────────────────────────────────────────────────────────────────────
class WeatherNotifier extends Notifier<WeatherState> {
  @override
  WeatherState build() {
    Future.microtask(() => detectAndFetch());
    return const WeatherState(isLoading: true);
  }

  /// Detecta localização real pelo browser (GPS/Wifi) ou fallback por IP.
  Future<void> detectAndFetch() async {
    state = state.copyWith(isLoading: true, error: null);

    double lat = state.latitude;
    double lon = state.longitude;
    String city = state.cityName;
    bool granted = false;

    // 1️⃣ Tenta permissão de geolocalização do browser
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        lat = pos.latitude;
        lon = pos.longitude;
        granted = true;
        // Reverse geocode via Open-Meteo timezone para obter cidade aproximada
        city = await _reverseGeocode(lat, lon);
      }
    } catch (_) {
      // Permissão negada ou timeout — fallback por IP
    }

    // 2️⃣ Fallback: localização por IP
    if (!granted) {
      try {
        final ipResp = await http
            .get(Uri.parse('http://ip-api.com/json/'))
            .timeout(const Duration(seconds: 5));
        if (ipResp.statusCode == 200) {
          final data = jsonDecode(ipResp.body) as Map<String, dynamic>;
          if (data['status'] == 'success') {
            lat = (data['lat'] as num).toDouble();
            lon = (data['lon'] as num).toDouble();
            final rawCity = data['city'] as String? ?? '';
            final region = data['regionName'] as String? ?? '';
            city = rawCity.isNotEmpty
                ? (region.isNotEmpty ? '$rawCity, $region' : rawCity)
                : city;
          }
        }
      } catch (_) {
        // fica com o default Petrolina
      }
    }

    state = state.copyWith(
      latitude: lat,
      longitude: lon,
      cityName: city,
      locationGranted: granted,
    );

    await _fetchForecast(lat, lon, city);
  }

  /// Busca previsão para coordenadas específicas (chamado ao selecionar cidade).
  Future<void> fetch({double? lat, double? lon, String? city}) async {
    final latitude = lat ?? state.latitude;
    final longitude = lon ?? state.longitude;
    final cityName = city ?? state.cityName;

    state = state.copyWith(
      isLoading: true,
      error: null,
      latitude: latitude,
      longitude: longitude,
      cityName: cityName,
    );
    await _fetchForecast(latitude, longitude, cityName);
  }

  Future<void> _fetchForecast(double lat, double lon, String city) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat'
        '&longitude=$lon'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,'
        'precipitation_sum,wind_speed_10m_max,uv_index_max'
        '&current_weather=true'
        '&forecast_days=5'
        '&timezone=America%2FSao_Paulo',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final forecast = WeatherForecast.fromJson(json);
        state = state.copyWith(
          isLoading: false,
          forecast: forecast,
          cityName: city,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Erro ao buscar previsão (${response.statusCode})',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sem conexão. Verifique sua internet.',
      );
    }
  }

  /// Reverse geocode simples via Open-Meteo timezone endpoint.
  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lon&format=json&accept-language=pt',
      );
      final resp = await http.get(
        url,
        headers: {'User-Agent': 'AquaGestor/1.0'},
      ).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};
        final city = address['city'] ??
            address['town'] ??
            address['village'] ??
            address['county'] ??
            '';
        final state_ = address['state'] as String? ?? '';
        if (city is String && city.isNotEmpty) {
          return state_.isNotEmpty ? '$city, $state_' : city;
        }
      }
    } catch (_) {}
    return 'Minha Localização';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Provider exposto
// ──────────────────────────────────────────────────────────────────────────────
final weatherProvider = NotifierProvider<WeatherNotifier, WeatherState>(
  WeatherNotifier.new,
);

// ──────────────────────────────────────────────────────────────────────────────
// Cidades pré-definidas
// ──────────────────────────────────────────────────────────────────────────────
const presetCities = [
  (name: 'Petrolina, PE', lat: -9.3984, lon: -40.5018),
  (name: 'Juazeiro, BA', lat: -9.4296, lon: -40.5025),
  (name: 'Sobral, CE', lat: -3.6904, lon: -40.3502),
  (name: 'Mossoró, RN', lat: -5.1878, lon: -37.3444),
  (name: 'Patos, PB', lat: -7.0244, lon: -37.2748),
  (name: 'Montes Claros, MG', lat: -16.7281, lon: -43.8653),
  (name: 'Palmas, TO', lat: -10.1840, lon: -48.3336),
  (name: 'Araguaína, TO', lat: -7.1919, lon: -48.2068),
];
