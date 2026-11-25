// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const EchoFxApp());

class EchoFxApp extends StatelessWidget {
  const EchoFxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ECHO FX',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D18),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const EchoHomePage(),
    );
  }
}

class EchoHomePage extends StatefulWidget {
  const EchoHomePage({super.key});

  @override
  State<EchoHomePage> createState() => _EchoHomePageState();
}

class _EchoHomePageState extends State<EchoHomePage> {
  static const _audio = MethodChannel('echo_fx/audio');
  bool _running = false;
  bool _busy = false;
  double _strength = 0.55;
  double _delay = 280;
  String _status = 'متوقف';

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_running) {
        await _audio.invokeMethod('stop');
        setState(() {
          _running = false;
          _status = 'متوقف';
        });
      } else {
        await _audio.invokeMethod('start', {
          'mix': _strength,
          'delayMs': _delay.round(),
        });
        setState(() {
          _running = true;
          _status = 'الصدى يعمل';
        });
      }
    } on PlatformException catch (e) {
      setState(() => _status = e.message ?? 'تعذر تشغيل المايك');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateEffect() async {
    if (!_running) return;
    try {
      await _audio.invokeMethod('setEcho', {
        'mix': _strength,
        'delayMs': _delay.round(),
      });
    } catch (_) {}
  }

  Future<void> _openTelegram() async {
    final Uri url = Uri.parse('https://t.me/IPP2I');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح التليجرام')),
        );
      }
    }
  }

  @override
  void dispose() {
    _audio.invokeMethod('stop');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
                        ),
                      ),
                      child: const Icon(Icons.graphic_eq_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 13),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ECHO FX',
                            style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4)),
                        Text('LIVE VOICE EFFECT',
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF8993AA),
                                letterSpacing: 2)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.more_horiz, color: Color(0xFF8993AA)),
                  ],
                ),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF171D31), Color(0xFF101525)],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(.07)),
                  ),
                  child: Column(
                    children: [
                      const Text('LIVE ECHO',
                          style: TextStyle(
                              color: Color(0xFF9AA6C0),
                              letterSpacing: 2,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 24),
                      Container(
                        width: 154,
                        height: 154,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10172A),
                          border: Border.all(
                              color: const Color(0xFF8B5CF6).withOpacity(.5),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF8B5CF6)
                                    .withOpacity(_running ? .28 : .08),
                                blurRadius: 35,
                                spreadRadius: 5),
                          ],
                        ),
                        child: Icon(Icons.mic_rounded,
                            size: 62,
                            color: _running
                                ? const Color(0xFFB9A1FF)
                                : const Color(0xFF68738D)),
                      ),
                      const SizedBox(height: 18),
                      Text(_status,
                          style: TextStyle(
                              color: _running
                                  ? const Color(0xFF67E8F9)
                                  : const Color(0xFF9AA6C0),
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _busy ? null : _toggle,
                          style: FilledButton.styleFrom(
                            backgroundColor: _running
                                ? const Color(0xFF252D43)
                                : const Color(0xFF7955E8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17)),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : Text(_running ? 'إيقاف الصدى' : 'تشغيل الصدى',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _settingCard(
                  title: 'قوة الصدى',
                  value: '${(_strength * 100).round()}%',
                  child: Slider(
                    value: _strength,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) {
                      setState(() => _strength = v);
                      _updateEffect();
                    },
                  ),
                ),
                const SizedBox(height: 14),
                _settingCard(
                  title: 'مدة التأخير',
                  value: '${_delay.round()} ms',
                  child: Slider(
                    value: _delay,
                    min: 80,
                    max: 700,
                    onChanged: (v) {
                      setState(() => _delay = v);
                      _updateEffect();
                    },
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151B2B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(.06)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.headphones_rounded, color: Color(0xFF67E8F9)),
                      SizedBox(width: 12),
                      Expanded(
                          child: Text(
                        'استخدم سماعات لتسمع الصدى بوضوح وتتجنب رجوع الصوت للمايك. هذا الإصدار يعالج الصوت داخل التطبيق فقط.',
                        style: TextStyle(
                            color: Color(0xFFABB5CA),
                            height: 1.5,
                            fontSize: 12),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                OutlinedButton.icon(
                  onPressed: _openTelegram,
                  icon: const Icon(Icons.telegram, color: Color(0xFF38BDF8)),
                  label: const Text('المطور: IPP2I'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(.13)),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 14),
                const Center(
                    child: Text('ECHO FX  •  VERSION 1.0',
                        style: TextStyle(
                            color: Color(0xFF566078),
                            fontSize: 10,
                            letterSpacing: 1.4))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingCard(
      {required String title,
      required String value,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Column(
        children: [
          Row(children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    color: Color(0xFFB9A1FF), fontWeight: FontWeight.bold)),
          ]),
          child,
        ],
      ),
    );
  }
}