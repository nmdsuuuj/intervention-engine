import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/chord_entry.dart';
import '../models/midi_track.dart';
import '../models/note.dart';
import '../models/section.dart';
import '../models/song.dart';
import 'track_view.dart';

class ArrangementView extends StatelessWidget {
  const ArrangementView({super.key, required this.song});

  final Song song;

  void _openTrackView(BuildContext context, Section section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => TrackView(section: section),
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
              _SongSummary(song: song),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: song.sections.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Section section = song.sections[index];
                    return _SectionCard(
                      section: section,
                      onOpenTrackView: () => _openTrackView(context, section),
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

class _SongSummary extends StatelessWidget {
  const _SongSummary({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold);
    final TextStyle subtitleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: Colors.white70, letterSpacing: 0.2);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.music_note,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Project BPM: ${song.bpm.toStringAsFixed(0)}',
                    style: titleStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sections: ${song.sections.length}',
                    style: subtitleStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.onOpenTrackView});

  final Section section;
  final VoidCallback onOpenTrackView;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        section.name,
                        style: theme.textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${section.lengthInBars} Bars',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onOpenTrackView,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('[ Track View へ ]'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _TrackLanePreview(title: '[Drums]', track: section.drums),
            const SizedBox(height: 12),
            _TrackLanePreview(title: '[Bass]', track: section.bass),
            const SizedBox(height: 12),
            _ChordLanePreview(chords: section.chords),
            const SizedBox(height: 12),
            _TrackLanePreview(title: '[Melody]', track: section.melody),
          ],
        ),
      ),
    );
  }
}

class _TrackLanePreview extends StatelessWidget {
  const _TrackLanePreview({required this.title, required this.track});

  final String title;
  final MidiTrack track;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int noteCount = track.notes.length;
    final double lastBeat = noteCount == 0
        ? 0
        : track.notes
              .map((Note note) => note.startTime + note.duration)
              .reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white10),
              color: const Color(0xFF0F172A),
            ),
            child: GridPaper(
              color: Colors.white12,
              divisions: 1,
              interval: 80,
              subdivisions: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('ノート数: $noteCount', style: theme.textTheme.bodyMedium),
                    Text(
                      '終端拍: ${lastBeat.toStringAsFixed(1)}',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChordLanePreview extends StatelessWidget {
  const _ChordLanePreview({required this.chords});

  final List<ChordEntry> chords;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String preview = chords.isEmpty
        ? 'Chords: ---'
        : chords
              .map((ChordEntry entry) => entry.chordName)
              .take(8)
              .join('  |  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '[Chord / Lyric]',
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white10),
              color: const Color(0xFF0F172A),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(preview, style: theme.textTheme.bodyMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
