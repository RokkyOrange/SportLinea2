import 'package:flutter/material.dart';
import 'package:sportlinea_app/api/api_client.dart';
import 'package:sportlinea_app/screens/app_root.dart';
import 'package:sportlinea_app/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SportLineaApp());
}

class SportLineaApp extends StatelessWidget {
  const SportLineaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'СпортЛиния',
      debugShowCheckedModeBanner: false,
      theme: Sl.theme(),
      builder: (context, child) => PhoneFrame(child: child ?? const SizedBox.shrink()),
      home: const _BootScreen(),
    );
  }
}

class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final framed = size.width >= 520;
    if (!framed) return child;
    final height = size.height - 36;
    return ColoredBox(
      color: Sl.frameOuter,
      child: Center(
        child: Container(
          width: 430,
          height: height,
          decoration: BoxDecoration(
            color: Sl.bg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: Color(0xFF0A1F18), spreadRadius: 10),
              BoxShadow(color: Sl.accent, spreadRadius: 12),
              BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 16)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(size: Size(430, height), padding: EdgeInsets.zero),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _BootScreen extends StatefulWidget {
  const _BootScreen();
  @override
  State<_BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<_BootScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final api = ApiClient.instance;
    await api.loadToken();
    if (!mounted) return;
    if (!api.isLoggedIn) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppRoot()));
      return;
    }
    try {
      final player = await api.me();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AppRoot(player: player)));
    } catch (_) {
      await api.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppRoot()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator(color: Sl.accent)));
  }
}
