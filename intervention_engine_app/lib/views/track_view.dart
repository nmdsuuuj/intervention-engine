import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/chord_entry.dart';
import '../models/midi_track.dart';
import '../models/note.dart';
import '../models/section.dart';

class TrackView extends StatefulWidget {
  const TrackView({super.key, required this.section});

  final Section section;

  @override
  State<TrackView> createState() => _TrackViewState();
}

class _TrackViewState extends State<TrackView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<_TrackTabData> tabs = <_TrackTabData>[
      _TrackTabData(
        label: 'Dr',
        builder: () => PianoRollView(track: widget.section.drums),
      ),
      _TrackTabData(
        label: 'Ba',
        builder: () => PianoRollView(track: widget.section.bass),
      ),
      _TrackTabData(
        label: 'Ch',
        builder: () => _ChordLaneView(chords: widget.section.chords),
      ),
      _TrackTabData(
        label: 'Me',
        builder: () => PianoRollView(track: widget.section.melody),
      ),
    ];

    final Widget activeView = tabs[_selectedIndex].builder();

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
                        child: _TrackTopBar(
                          tabs: tabs,
                          selectedIndex: _selectedIndex,
                          onTabSelected: (int index) {
                            setState(() => _selectedIndex = index);
                          },
                          section: widget.section,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E1526),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: activeView,
                            ),
                          ),
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

class _TrackTabData {
  const _TrackTabData({required this.label, required this.builder});

  final String label;
  final Widget Function() builder;
}

class _TrackTopBar extends StatelessWidget {
  const _TrackTopBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.section,
  });

  final List<_TrackTabData> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Section section;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String chordSummary = section.chords.isEmpty
        ? 'Chords: ---'
        : section.chords.map((ChordEntry entry) => entry.chordName).join(' > ');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF1F2937),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: List<Widget>.generate(tabs.length, (int index) {
                  final bool isSelected = index == selectedIndex;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onTabSelected(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : Colors.transparent,
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            tabs[index].label,
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF111D2F),
                border: Border.all(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Section: ${section.name}  •  Bars: ${section.lengthInBars}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chordSummary,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PianoRollView extends StatelessWidget {
  const PianoRollView({super.key, required this.track});

  final MidiTrack track;

  @override
  Widget build(BuildContext context) {
    if (track.notes.isEmpty) {
      return Center(
        child: Text(
          '${track.name} にノートがありません',
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(color: Colors.white54),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double beatWidth = 72;
        const double noteHeight = 18;

        final List<Note> notes = track.notes;
        final int minPitch = notes
            .map((Note note) => note.pitch)
            .reduce(math.min);
        final int maxPitch = notes
            .map((Note note) => note.pitch)
            .reduce(math.max);
        final double maxBeat = notes
            .map((Note note) => note.startTime + note.duration)
            .reduce(math.max);

        final double contentWidth = math.max(
          constraints.maxWidth,
          (maxBeat + 1) * beatWidth,
        );
        final double contentHeight = math.max(
          constraints.maxHeight,
          (maxPitch - minPitch + 1) * noteHeight,
        );

        return Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentWidth,
              height: contentHeight,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridBackgroundPainter(
                        beatWidth: beatWidth,
                        noteHeight: noteHeight,
                        minPitch: minPitch,
                        maxPitch: maxPitch,
                      ),
                    ),
                  ),
                  ...notes.map((Note note) {
                    final double left = note.startTime * beatWidth;
                    final double width = math.max(note.duration * beatWidth, 4);
                    final double top = (maxPitch - note.pitch) * noteHeight;
                    return Positioned(
                      left: left,
                      top: top,
                      width: width,
                      height: noteHeight,
                      child: _NoteBlock(note: note),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  _GridBackgroundPainter({
    required this.beatWidth,
    required this.noteHeight,
    required this.minPitch,
    required this.maxPitch,
  });

  final double beatWidth;
  final double noteHeight;
  final int minPitch;
  final int maxPitch;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint beatPaint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1;
    final Paint subdivisionPaint = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += beatWidth) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), beatPaint);
      for (int i = 1; i < 4; i++) {
        final double subdivisionX = x + (beatWidth / 4) * i;
        canvas.drawLine(
          Offset(subdivisionX, 0),
          Offset(subdivisionX, size.height),
          subdivisionPaint,
        );
      }
    }

    for (int pitch = minPitch; pitch <= maxPitch; pitch++) {
      final double y = (maxPitch - pitch + 1) * noteHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), subdivisionPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final Color color = _velocityToColor(
      note.velocity,
      Theme.of(context).colorScheme.primary,
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black26),
      ),
      child: Center(
        child: Text(
          '${note.pitch}',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _velocityToColor(int velocity, Color baseColor) {
    final double opacity = switch (velocity) {
      <= 0 => 0.3,
      1 => 0.4,
      2 => 0.6,
      3 => 0.8,
      _ => 1.0,
    };
    final double normalized = opacity.clamp(0.3, 1.0).toDouble();
    return baseColor.withValues(alpha: normalized);
  }
}

class _ChordLaneView extends StatelessWidget {
  const _ChordLaneView({required this.chords});

  final List<ChordEntry> chords;

  @override
  Widget build(BuildContext context) {
    if (chords.isEmpty) {
      return Center(
        child: Text(
          'コードが未設定です',
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(color: Colors.white54),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: chords.length,
      itemBuilder: (BuildContext context, int index) {
        final ChordEntry entry = chords[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: const Color(0x11111111),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          title: Text(
            entry.chordName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: entry.lyric != null
              ? Text(
                  entry.lyric!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(color: Colors.white70),
                )
              : null,
          trailing: Text(
            '${entry.startTime.toStringAsFixed(1)} 拍',
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: Colors.white70),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    final ThemeData theme = Theme.of(context);

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
          const _ControlButton(label: '[ Select ]', icon: Icons.touch_app),
          const SizedBox(height: 12),
          const _ControlButton(label: '[ Write ]', icon: Icons.edit),
          const SizedBox(height: 12),
          const _ControlButton(label: '[ Snap ]', icon: Icons.grid_view),
          const SizedBox(height: 12),
          const _ControlButton(label: '[ Octave ↑ ]', icon: Icons.arrow_upward),
          const SizedBox(height: 12),
          const _ControlButton(
            label: '[ Octave ↓ ]',
            icon: Icons.arrow_downward,
          ),
          const SizedBox(height: 20),
          _ControlButton(
            label: '[ MUTATE ]',
            icon: Icons.auto_awesome,
            height: 88,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(88),
              backgroundColor: theme.colorScheme.primary,
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _ControlButton(label: '[ Hum ]', icon: Icons.mic, height: 64),
        ],
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
        children: const <Widget>[
          _ControlButton(label: '[ Guide ]', icon: Icons.filter_alt),
          SizedBox(height: 12),
          _ControlButton(label: '[ Save ]', icon: Icons.save),
          SizedBox(height: 12),
          _ControlButton(label: '[ Metronome ]', icon: Icons.av_timer),
          SizedBox(height: 12),
          _ControlButton(label: '[ Redo ]', icon: Icons.redo),
          SizedBox(height: 12),
          _ControlButton(
            label: '[ Undo ]',
            icon: Icons.undo,
            height: 72,
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Spacer(),
          _ControlButton(
            label: '[ Play / Stop ]',
            icon: Icons.play_arrow,
            height: 88,
            textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
