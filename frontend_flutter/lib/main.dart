import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_flutter/core/theme/theme_provider.dart';
import 'package:frontend_flutter/core/routing/app_router.dart';
import 'package:frontend_flutter/core/api/server_ping_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AquaSertaoApp(),
    ),
  );
}



class AquaSertaoApp extends ConsumerWidget {
  const AquaSertaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AquaSertão',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003366),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003366),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF38BDF8), // Bright Sky Blue for main actions
        scaffoldBackgroundColor: const Color(0xFF090D16), // Premium Deep Slate Black
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF151D30), // Sleek Dark Slate Blue for cards
          background: Color(0xFF090D16),
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF151D30),
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF151D30),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF263350), width: 1.0), // High contrast border for cards
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF151D30),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(color: Color(0xFF263350), width: 1.0),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF151D30),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF263350), width: 1.0),
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          headerBackgroundColor: const Color(0xFF151D30),
          headerForegroundColor: Colors.white,
          backgroundColor: const Color(0xFF151D30),
          dayForegroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.black;
            }
            return Colors.white;
          }),
          todayForegroundColor: MaterialStateProperty.all(const Color(0xFF38BDF8)),
          yearForegroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.black;
            }
            return Colors.white;
          }),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Color(0xFFE2E8F0)), // Slate 200
          bodySmall: TextStyle(color: Color(0xFF94A3B8)), // Slate 400
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      routerConfig: router,
      builder: (context, child) {
        final serverStatus = ref.watch(serverPingProvider);
        return Stack(
          children: [
            if (child != null) child,
            if (serverStatus == ServerStatus.sleeping || serverStatus == ServerStatus.error)
              ServerWakeUpOverlay(status: serverStatus),
          ],
        );
      },
    );
  }
}

class ServerWakeUpOverlay extends ConsumerWidget {
  final ServerStatus status;
  const ServerWakeUpOverlay({super.key, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isDark ? const Color(0xFF090D16) : Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [              if (status == ServerStatus.sleeping) ...[
                const FishSwimAnimation(),
                const SizedBox(height: 40),
                Text(
                  'Acordando Servidor...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF003366),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Como utilizamos um servidor gratuito (Render) para demonstração, o servidor entra em repouso após inatividade e pode levar até 1 minuto para acordar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Agradecemos a sua paciência! 🌊',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF13A538),
                  ),
                ),
              ] else if (status == ServerStatus.error) ...[
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.redAccent,
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  'Conexão Instável',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF003366),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Não foi possível estabelecer contato com o servidor. Por favor, verifique sua conexão de rede ou tente novamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(serverPingProvider.notifier).checkServer();
                    },
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: const Text('Tentar Novamente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF13A538),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DummyScreen extends StatelessWidget {
  final String title;
  const DummyScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title em breve!', style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class FishSwimAnimation extends StatefulWidget {
  const FishSwimAnimation({super.key});

  @override
  State<FishSwimAnimation> createState() => _FishSwimAnimationState();
}

class _FishSwimAnimationState extends State<FishSwimAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _swimmingRight = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _animation = Tween<double>(begin: -1.2, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _swimmingRight = false;
          });
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          setState(() {
            _swimmingRight = true;
          });
          _controller.forward();
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bubbles
          ...List.generate(12, (index) => _Bubble(index: index)),
          
          // Swimming Fish
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Align(
                alignment: Alignment(_animation.value, 0),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(_swimmingRight ? 1.0 : -1.0, 1.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🐟',
                          style: TextStyle(fontSize: 48, decoration: TextDecoration.none),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatefulWidget {
  final int index;
  const _Bubble({required this.index});

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _verticalAnimation;
  late final Animation<double> _horizontalAnimation;
  late double _startX;
  late double _size;

  @override
  void initState() {
    super.initState();
    _startX = (widget.index * 137) % 300 - 150.0;
    _size = 4.0 + (widget.index % 4) * 3.0;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000 + (widget.index % 3) * 600),
    );

    _verticalAnimation = Tween<double>(begin: 80, end: -80).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _horizontalAnimation = Tween<double>(begin: 0, end: (widget.index % 2 == 0 ? 15 : -15)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    Future.delayed(Duration(milliseconds: widget.index * 250), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_startX + _horizontalAnimation.value, _verticalAnimation.value),
          child: Opacity(
            opacity: (1.0 - _controller.value).clamp(0.0, 0.8),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: Colors.blue.shade300.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade200.withOpacity(0.8), width: 1),
              ),
            ),
          ),
        );
      },
    );
  }
}
