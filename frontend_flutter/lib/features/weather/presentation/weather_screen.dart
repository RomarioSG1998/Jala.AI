import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend_flutter/features/weather/providers/weather_provider.dart';
import 'package:frontend_flutter/features/weather/data/weather_model.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showCityPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF151D30) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selecionar Localização',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Regiões aquícolas do Brasil',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 12),
              // Botão: usar localização real do dispositivo
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(weatherProvider.notifier).detectAndFetch();
                  _fadeController
                    ..reset()
                    ..forward();
                },
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Usar minha localização atual'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0055A5),
                  side: const BorderSide(color: Color(0xFF0055A5)),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...presetCities.map((city) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0055A5).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Color(0xFF0055A5), size: 20),
                  ),
                  title: Text(
                    city.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    '${city.lat.toStringAsFixed(4)}, ${city.lon.toStringAsFixed(4)}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                  trailing: Icon(Icons.chevron_right,
                      color: Colors.grey.shade400, size: 20),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(weatherProvider.notifier).fetch(
                          lat: city.lat,
                          lon: city.lon,
                          city: city.name,
                        );
                    _fadeController
                      ..reset()
                      ..forward();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Header com degradê ───────────────────────────────────────────
          _WeatherHeader(
            cityName: weatherState.cityName,
            locationGranted: weatherState.locationGranted,
            onCityTap: _showCityPicker,
            onRefresh: () {
              ref.read(weatherProvider.notifier).detectAndFetch();
              _fadeController
                ..reset()
                ..forward();
            },
            isDark: isDark,
          ),

          // ── Conteúdo ─────────────────────────────────────────────────────
          Expanded(
            child: weatherState.isLoading
                ? _buildLoading()
                : weatherState.error != null
                    ? _buildError(weatherState.error!, isDark)
                    : weatherState.forecast != null
                        ? FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildForecast(
                                weatherState.forecast!, isDark),
                          )
                        : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF0055A5)),
          SizedBox(height: 16),
          Text('Carregando previsão do tempo...',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildError(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🌩️', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(weatherProvider.notifier).fetch(),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Tentar novamente',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecast(WeatherForecast forecast, bool isDark) {
    final today = forecast.days.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        // ── Card principal do dia atual ──────────────────────────────────
        _TodayCard(day: today, isDark: isDark),
        const SizedBox(height: 16),

        // ── Grade de detalhes do dia atual ───────────────────────────────
        _TodayDetailsGrid(day: today, isDark: isDark),
        const SizedBox(height: 20),

        // ── Título próximos dias ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'PRÓXIMOS 5 DIAS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isDark ? Colors.grey.shade400 : Colors.black54,
            ),
          ),
        ),

        // ── Cards dos próximos 4 dias ────────────────────────────────────
        ...forecast.days.asMap().entries.map((entry) {
          final i = entry.key;
          final day = entry.value;
          return _DayForecastCard(
            day: day,
            isToday: i == 0,
            isDark: isDark,
          );
        }),

        const SizedBox(height: 12),

        // ── Nota da fonte ─────────────────────────────────────────────────
        Center(
          child: Text(
            'Dados: Open-Meteo API • Atualizado agora',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Header com degradê azul
// ──────────────────────────────────────────────────────────────────────────────
class _WeatherHeader extends StatelessWidget {
  final String cityName;
  final bool locationGranted;
  final VoidCallback onCityTap;
  final VoidCallback onRefresh;
  final bool isDark;

  const _WeatherHeader({
    required this.cityName,
    required this.locationGranted,
    required this.onCityTap,
    required this.onRefresh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F1E3A), const Color(0xFF1A3A6A)]
              : [const Color(0xFF003366), const Color(0xFF0055A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003366).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🌤️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'PREVISÃO DO TEMPO',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (locationGranted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.my_location,
                                color: Colors.greenAccent, size: 9),
                            SizedBox(width: 3),
                            Text('GPS',
                                style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onCityTap,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          cityName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white70, size: 22),
            tooltip: 'Atualizar',
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Card do dia atual (grande)
// ──────────────────────────────────────────────────────────────────────────────
class _TodayCard extends StatelessWidget {
  final WeatherDay day;
  final bool isDark;

  const _TodayCard({required this.day, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A3A6A), const Color(0xFF0F2847)]
              : [const Color(0xFF0055A5), const Color(0xFF0079C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0055A5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HOJE',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMM', 'pt_BR').format(day.date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${day.tempMax.round()}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mín: ${day.tempMin.round()}°C',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    day.info.emoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day.info.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Grade de detalhes (vento, chuva, UV)
// ──────────────────────────────────────────────────────────────────────────────
class _TodayDetailsGrid extends StatelessWidget {
  final WeatherDay day;
  final bool isDark;

  const _TodayDetailsGrid({required this.day, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF151D30) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF263350) : Colors.grey.shade100;

    return Row(
      children: [
        _DetailTile(
          emoji: '💨',
          label: 'Vento',
          value: '${day.windSpeedMax.round()} km/h',
          cardColor: cardColor,
          borderColor: borderColor,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _DetailTile(
          emoji: '🌧️',
          label: 'Precipitação',
          value: '${day.precipitationSum.toStringAsFixed(1)} mm',
          cardColor: cardColor,
          borderColor: borderColor,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _DetailTile(
          emoji: '☀️',
          label: 'Índice UV',
          value: day.uvIndexMax.toStringAsFixed(1),
          cardColor: cardColor,
          borderColor: borderColor,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color cardColor;
  final Color borderColor;
  final bool isDark;

  const _DetailTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.cardColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Card de cada dia (linha)
// ──────────────────────────────────────────────────────────────────────────────
class _DayForecastCard extends StatelessWidget {
  final WeatherDay day;
  final bool isToday;
  final bool isDark;

  const _DayForecastCard({
    required this.day,
    required this.isToday,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF151D30) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF263350) : Colors.grey.shade100;

    final dayLabel = isToday
        ? 'Hoje'
        : DateFormat('EEEE', 'pt_BR').format(day.date);
    final dateLabel = DateFormat('d/MM', 'pt_BR').format(day.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isToday
            ? (isDark
                ? const Color(0xFF1A3A6A).withOpacity(0.6)
                : const Color(0xFFE8F3FF))
            : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? const Color(0xFF0055A5).withOpacity(0.4) : borderColor,
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Dia da semana
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? const Color(0xFF0055A5)
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Emoji + condição
          Text(day.info.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              day.info.label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Chuva
          if (day.precipitationSum > 0) ...[
            const Text('🌧️', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 2),
            Text(
              '${day.precipitationSum.toStringAsFixed(0)}mm',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Temperaturas
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${day.tempMax.round()}°',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF003366),
                ),
              ),
              Text(
                '${day.tempMin.round()}°',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
