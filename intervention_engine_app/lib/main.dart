import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const InterventionEngineApp());
}

class InterventionEngineApp extends StatelessWidget {
  const InterventionEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Intervention Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        textTheme: ThemeData(
          brightness: Brightness.dark,
        ).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const ArrangementView(),
    );
  }
}

class ArrangementView extends StatelessWidget {
  const ArrangementView({super.key});

  static const List<String> _lanes = <String>[
    '[Structure]',
    '[Audio (歌)]',
    '[Chord / Lyric]',
    '[Drums]',
    '[Bass]',
    '[Melody]',
  ];

  void _openTrackView(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const TrackView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Arrangement View'),
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _TimelineHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _lanes.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _ArrangementLane(
                      label: _lanes[index],
                      onOpenTrackView: () => _openTrackView(context),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader();

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = Theme.of(context).textTheme.titleSmall!
        .copyWith(color: Colors.white70, fontWeight: FontWeight.w600);

    return SizedBox(
      height: 72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1E293B),
          border: Border.all(color: Colors.white12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(
              8,
              (int index) => Text(
                '${(index + 1).toString().padLeft(2, '0')} 小節',
                style: labelStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrangementLane extends StatelessWidget {
  const _ArrangementLane({required this.label, required this.onOpenTrackView});

  final String label;
  final VoidCallback onOpenTrackView;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = Colors.white12;
    final Color surfaceColor = const Color(0xFF1E293B);

    return Card(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'タップで詳細編集',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall!.copyWith(color: Colors.white60),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: onOpenTrackView,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('[ Track View へ ]'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 130,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    color: const Color(0xFF0F172A),
                  ),
                  child: GridPaper(
                    color: Colors.white12,
                    divisions: 1,
                    interval: 80,
                    subdivisions: 4,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'タイムライン・プレースホルダー',
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackView extends StatelessWidget {
  const TrackView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Row(
              children: <Widget>[
                _TrackColumnContainer(
                  width: constraints.maxWidth * 0.15,
                  child: _TrackLeftColumn(
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
                _TrackColumnContainer(
                  width: constraints.maxWidth * 0.70,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: constraints.maxHeight * 0.1,
                        child: const _TrackTopBar(),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: const _PianoRollPlaceholder(),
                        ),
                      ),
                    ],
                  ),
                ),
                _TrackColumnContainer(
                  width: constraints.maxWidth * 0.15,
                  child: const _TrackRightColumn(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TrackColumnContainer extends StatelessWidget {
  const _TrackColumnContainer({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TrackLeftColumn extends StatelessWidget {
  const _TrackLeftColumn({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _ControlButton(
            label: '[ Back ]',
            icon: Icons.arrow_back,
            onPressed: onBack,
          ),
          const SizedBox(height: 12),
          _ControlButton(label: '[ Select ]', icon: Icons.touch_app),
          const SizedBox(height: 12),
          _ControlButton(label: '[ Write ]', icon: Icons.edit),
          const SizedBox(height: 12),
          _ControlButton(label: '[ Snap ]', icon: Icons.grid_view),
          const SizedBox(height: 12),
          _ControlButton(label: '[ Octave ↑ ]', icon: Icons.arrow_upward),
          const SizedBox(height: 12),
          _ControlButton(label: '[ Octave ↓ ]', icon: Icons.arrow_downward),
          const SizedBox(height: 20),
          _ControlButton(
            label: '[ MUTATE ]',
            icon: Icons.auto_awesome,
            height: 88,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(88),
              backgroundColor: Theme.of(context).colorScheme.primary,
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _ControlButton(label: '[ Hum ]', icon: Icons.mic, height: 64),
        ],
      ),
    );
  }
}

class _TrackTopBar extends StatelessWidget {
  const _TrackTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF1F2937),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: const <Widget>[
                  Expanded(child: _TrackTab(label: 'Dr')),
                  Expanded(child: _TrackTab(label: 'Ba')),
                  Expanded(child: _TrackTab(label: 'Ch')),
                  Expanded(child: _TrackTab(label: 'Me')),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF111D2F),
                border: Border.all(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '4:01 | Cmaj7 > G7 > F > G',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackTab extends StatelessWidget {
  const _TrackTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PianoRollPlaceholder extends StatelessWidget {
  const _PianoRollPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E1526),
          border: Border.all(color: Colors.white12),
        ),
        child: GridPaper(
          color: Colors.white12,
          divisions: 1,
          interval: 80,
          subdivisions: 4,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Piano Roll Placeholder',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackRightColumn extends StatelessWidget {
  const _TrackRightColumn();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const _ControlButton(label: '[ Guide ]', icon: Icons.filter_alt),
          const SizedBox(height: 12),
          const _ControlButton(label: '[ Save ]', icon: Icons.save),
          const SizedBox(height: 12),
          const _ControlButton(label: '[ Metronome ]', icon: Icons.av_timer),
          const SizedBox(height: 12),
          const _ControlButton(label: '[ Redo ]', icon: Icons.redo),
          const SizedBox(height: 12),
          _ControlButton(
            label: '[ Undo ]',
            icon: Icons.undo,
            height: 72,
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _ControlButton(
            label: '[ Play / Stop ]',
            icon: Icons.play_arrow,
            height: 88,
            textStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.height = 56,
    this.style,
    this.textStyle,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double height;
  final ButtonStyle? style;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle baseStyle = FilledButton.styleFrom(
      minimumSize: Size.fromHeight(height),
      textStyle:
          textStyle ??
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );

    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: baseStyle.merge(style),
    );
  }
}
