import 'package:flutter/material.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  bool _running = false;
  String _phaseText = 'Tap to Begin';
  int _phaseIndex = 0;
  int _cycles = 0;

  static const _labels    = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  static const _durations = [4000, 4000, 4000, 4000];
  static const _colors    = [
    Color(0xFF6BBFB5),
    Color(0xFF6B9EFF),
    Color(0xFF9C8FE6),
    Color(0xFF6B9EFF),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000));
    _anim = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running    = true;
      _phaseIndex = 0;
      _cycles     = 0;
    });
    _tick();
  }

  void _stop() {
    _ctrl.stop();
    setState(() {
      _running    = false;
      _phaseText  = 'Tap to Begin';
      _phaseIndex = 0;
      _cycles     = 0;
    });
  }

  Future<void> _tick() async {
    while (_running && mounted) {
      final idx = _phaseIndex % 4;
      setState(() => _phaseText = _labels[idx]);
      _ctrl.duration = Duration(milliseconds: _durations[idx]);

      if (idx == 0) {
        await _ctrl.forward();
      } else if (idx == 2) {
        await _ctrl.reverse();
      } else {
        await Future.delayed(Duration(milliseconds: _durations[idx]));
      }

      if (!mounted || !_running) break;
      _phaseIndex++;
      if (_phaseIndex % 4 == 0) setState(() => _cycles++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _running
        ? _colors[_phaseIndex % 4]
        : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Breathing Exercise')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Box Breathing',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '4‑4‑4‑4 · calm your nervous system',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 52),

              GestureDetector(
                onTap: _running ? _stop : _start,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) {
                    final s = _running ? _anim.value : 0.65;
                    return Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.08),
                      ),
                      child: Center(
                        child: Transform.scale(
                          scale: s,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                color.withOpacity(0.75),
                                color.withOpacity(0.30),
                              ]),
                            ),
                            child: Center(
                              child: Text(
                                _phaseText,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 44),

              if (_running) ...[
                Text(
                  'Cycles completed: $_cycles',
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                    onPressed: _stop, child: const Text('Stop')),
              ] else
                Text(
                  'Tap the circle to begin',
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              const SizedBox(height: 44),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant
                      .withOpacity(0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (i) => Column(children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: _colors[i],
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(height: 4),
                    Text(_labels[i],
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                    Text('4s',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500)),
                  ])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}