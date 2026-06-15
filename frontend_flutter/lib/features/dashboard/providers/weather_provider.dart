import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeatherData {
  final double temperature;
  final String weatherDescription;
  final double windSpeed;
  final int weatherCode;
  final String cityName;

  WeatherData({
    required this.temperature,
    required this.weatherDescription,
    required this.windSpeed,
    required this.weatherCode,
    required this.cityName,
  });
}

final weatherProvider = FutureProvider<WeatherData>((ref) async {
  double lat = -9.3891; // Padrão: Petrolina, PE
  double lon = -40.5027;
  String city = 'Petrolina';
  final dio = Dio();

  try {
    // Busca a localização exata baseada no IP da rede
    final ipResponse = await dio.get('http://ip-api.com/json/');
    if (ipResponse.statusCode == 200 && ipResponse.data['status'] == 'success') {
      lat = (ipResponse.data['lat'] as num).toDouble();
      lon = (ipResponse.data['lon'] as num).toDouble();
      if (ipResponse.data['city'] != null) {
        city = ipResponse.data['city'] as String;
      }
    }
  } catch (e) {
    print('Erro ao obter IP location: $e');
  }

  final response = await dio.get(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');

  final current = response.data['current_weather'];
  final temp = (current['temperature'] as num).toDouble();
  final windSpeed = (current['windspeed'] as num).toDouble();
  final weatherCode = current['weathercode'] as int;

  String desc = 'Desconhecido';
  if (weatherCode == 0) {
    desc = 'Céu limpo';
  } else if (weatherCode == 1 || weatherCode == 2 || weatherCode == 3) {
    desc = 'Parcialmente nublado';
  } else if (weatherCode == 45 || weatherCode == 48) {
    desc = 'Névoa';
  } else if (weatherCode >= 51 && weatherCode <= 69) {
    desc = 'Chuvoso';
  } else if (weatherCode >= 71 && weatherCode <= 77) {
    desc = 'Neve';
  } else if (weatherCode >= 80 && weatherCode <= 82) {
    desc = 'Pancadas de chuva';
  } else if (weatherCode >= 95) {
    desc = 'Tempestade';
  }

  return WeatherData(
    temperature: temp,
    weatherDescription: desc,
    windSpeed: windSpeed,
    weatherCode: weatherCode,
    cityName: city,
  );
});
