class WeatherDay {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double precipitationSum;
  final double windSpeedMax;
  final int weatherCode;
  final double uvIndexMax;

  const WeatherDay({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationSum,
    required this.windSpeedMax,
    required this.weatherCode,
    required this.uvIndexMax,
  });

  WeatherInfo get info => WeatherInfo.fromCode(weatherCode);
}

class WeatherInfo {
  final String emoji;
  final String label;

  const WeatherInfo(this.emoji, this.label);

  factory WeatherInfo.fromCode(int code) {
    if (code == 0) return const WeatherInfo('☀️', 'Céu limpo');
    if (code <= 3) return const WeatherInfo('🌤️', 'Parcialmente nublado');
    if (code <= 9) return const WeatherInfo('🌫️', 'Neblina');
    if (code <= 19) return const WeatherInfo('🌧️', 'Chuva leve');
    if (code <= 29) return const WeatherInfo('⛈️', 'Tempestade');
    if (code <= 39) return const WeatherInfo('🌨️', 'Neve');
    if (code <= 49) return const WeatherInfo('🌫️', 'Neblina densa');
    if (code <= 59) return const WeatherInfo('🌦️', 'Garoa');
    if (code <= 69) return const WeatherInfo('🌧️', 'Chuva');
    if (code <= 79) return const WeatherInfo('❄️', 'Neve');
    if (code <= 84) return const WeatherInfo('🌦️', 'Pancadas de chuva');
    if (code <= 94) return const WeatherInfo('⛈️', 'Trovoadas');
    return const WeatherInfo('⛈️', 'Tempestade severa');
  }
}

class WeatherForecast {
  final double latitude;
  final double longitude;
  final String timezone;
  final List<WeatherDay> days;

  // Dados do tempo atual (current_weather)
  final double? currentTemp;
  final double? currentWindSpeed;
  final int? currentWeatherCode;

  const WeatherForecast({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.days,
    this.currentTemp,
    this.currentWindSpeed,
    this.currentWeatherCode,
  });

  WeatherInfo get currentInfo =>
      WeatherInfo.fromCode(currentWeatherCode ?? (days.isNotEmpty ? days.first.weatherCode : 0));

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>;
    final dates = (daily['time'] as List).cast<String>();
    final tempMax = (daily['temperature_2m_max'] as List).cast<num>();
    final tempMin = (daily['temperature_2m_min'] as List).cast<num>();
    final precip = (daily['precipitation_sum'] as List).cast<num>();
    final wind = (daily['wind_speed_10m_max'] as List).cast<num>();
    final codes = (daily['weather_code'] as List).cast<num>();
    final uv = (daily['uv_index_max'] as List).cast<num>();

    final days = <WeatherDay>[];
    for (int i = 0; i < dates.length; i++) {
      days.add(WeatherDay(
        date: DateTime.parse(dates[i]),
        tempMax: tempMax[i].toDouble(),
        tempMin: tempMin[i].toDouble(),
        precipitationSum: precip[i].toDouble(),
        windSpeedMax: wind[i].toDouble(),
        weatherCode: codes[i].toInt(),
        uvIndexMax: uv[i].toDouble(),
      ));
    }

    // current_weather (opcional)
    double? currentTemp;
    double? currentWindSpeed;
    int? currentWeatherCode;
    if (json.containsKey('current_weather')) {
      final cw = json['current_weather'] as Map<String, dynamic>;
      currentTemp = (cw['temperature'] as num?)?.toDouble();
      currentWindSpeed = (cw['windspeed'] as num?)?.toDouble();
      currentWeatherCode = (cw['weathercode'] as num?)?.toInt();
    }

    return WeatherForecast(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String,
      days: days,
      currentTemp: currentTemp,
      currentWindSpeed: currentWindSpeed,
      currentWeatherCode: currentWeatherCode,
    );
  }
}
