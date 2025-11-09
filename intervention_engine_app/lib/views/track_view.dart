import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/chord_entry.dart';
import '../models/midi_track.dart';
import '../models/note.dart';
import '../models/section.dart';

enum Tool { select, write }

enum Snap { bar, beat, grid, free }

enum _TrackLayer { drums, bass, melody }

extension SnapInfo on Snap {
  String get label => switch (this) {
    Snap.bar => 'Bar',
    Snap.beat => 'Beat',
    Snap.grid => 'Grid',
    Snap.free => 'Free',
  };

  String get description => switch (this) {
    Snap.bar => '小節単位でノートを配置',
    Snap.beat => '拍単位でノートを配置',
    Snap.grid => '細かいグリッド (1/4拍) にスナップ',
    Snap.free => 'スナップなし（自由配置）',
  };
}

extension ToolInfo on Tool {
  String get label => switch (this) {
    Tool.select => 'Select',
    Tool.write => 'Write',
  };
}

const double _kBeatWidth = 72;
const double _kNoteHeight = 20;
const double _kMinNoteDuration = 0.25;

double _roundToDecimals(double value, int decimals) {
  final double factor = math.pow(10, decimals).toDouble();
  return (value * factor).roundToDouble() / factor;
}

double _snapStep(Snap snap) {
  switch (snap) {
    case Snap.bar:
      return 4.0;
    case Snap.beat:
      return 1.0;
    case Snap.grid:
      return 0.25;
    case Snap.free:
      return 0.125;
  }
}

double _quantize(double value, Snap snap) {
  if (snap == Snap.free) {
    return _roundToDecimals(value, 3);
  }
  final double step = _snapStep(snap);
  return (value / step).roundToDouble() * step;
}

double _quantizeFloor(double value, Snap snap) {
  if (snap == Snap.free) {
    return _roundToDecimals(value, 3);
  }
  final double step = _snapStep(snap);
  return (value / step).floorToDouble() * step;
}

double _quantizeDuration(double value, Snap snap) {
  if (snap == Snap.free) {
    return math.max(_kMinNoteDuration, _roundToDecimals(value, 3));
  }
  final double step = _snapStep(snap);
  final double quantized = (value / step).roundToDouble() * step;
  return math.max(_kMinNoteDuration, quantized);
}

double _defaultDuration(Snap snap) {
  if (snap == Snap.free) {
    return 1.0;
  }
  return math.max(_kMinNoteDuration, _snapStep(snap));
}

int _noteComparator(Note a, Note b) {
  final int startCompare = a.startTime.compareTo(b.startTime);
  if (startCompare != 0) {
    return startCompare;
  }
  return a.pitch.compareTo(b.pitch);
}

class TrackView extends StatefulWidget {
  const TrackView({super.key, required this.section});

  final Section section;

  @override
  State<TrackView> createState() => _TrackViewState();
}

class _TrackViewState extends State<TrackView> {
  late Section _section;
  int _selectedIndex = 0;
  Tool _activeTool = Tool.select;
  Snap _activeSnap = Snap.grid;
  Note? _selectedNote;

  @override
  void initState() {
    super.initState();
    _section = widget.section;
  }

  @override
  void didUpdateWidget(covariant TrackView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.section, widget.section)) {
      _section = widget.section;
      _selectedNote = null;
    }
  }

  _TrackLayer? _layerForTabIndex(int index) {
    switch (index) {
      case 0:
        return _TrackLayer.drums;
      case 1:
        return _TrackLayer.bass;
      case 3:
        return _TrackLayer.melody;
      default:
        return null;
    }
  }

  Note? _selectedNoteForLayer(_TrackLayer layer) {
    return _layerForTabIndex(_selectedIndex) == layer ? _selectedNote : null;
  }

  void _handleTabSelected(int index) {
    if (_selectedIndex == index) {
      return;
    }
    setState(() {
      _selectedIndex = index;
      _selectedNote = null;
    });
  }

  void _handleToolChanged(Tool tool) {
    if (_activeTool == tool) {
      return;
    }
    setState(() {
      _activeTool = tool;
      if (tool != Tool.select) {
        _selectedNote = null;
      }
    });
  }

  void _handleSnapChanged(Snap snap) {
    if (_activeSnap == snap) {
      return;
    }
    setState(() {
      _activeSnap = snap;
    });
  }

  void _handleSelectNote(Note? note) {
    if (_layerForTabIndex(_selectedIndex) == null) {
      return;
    }
    setState(() {
      _selectedNote = note;
    });
  }

  void _updateTrackNotes(
    _TrackLayer layer,
    List<Note> notes,
    Note? selectedNote,
  ) {
    setState(() {
      switch (layer) {
        case _TrackLayer.drums:
          _section = _section.copyWith(
            drums: _section.drums.copyWith(notes: notes),
          );
          break;
        case _TrackLayer.bass:
          _section = _section.copyWith(
            bass: _section.bass.copyWith(notes: notes),
          );
          break;
        case _TrackLayer.melody:
          _section = _section.copyWith(
            melody: _section.melody.copyWith(notes: notes),
          );
          break;
      }

      if (_layerForTabIndex(_selectedIndex) == layer) {
        if (selectedNote != null && notes.contains(selectedNote)) {
          _selectedNote = selectedNote;
        } else if (selectedNote == null) {
          _selectedNote = null;
        } else if (!notes.contains(_selectedNote)) {
          _selectedNote = null;
        }
      }
    });
  }

  List<_TrackTabData> _buildTabs() {
    return <_TrackTabData>[
      _TrackTabData(
        label: 'Dr',
        layer: _TrackLayer.drums,
        builder: () => PianoRollView(
          track: _section.drums,
          activeTool: _activeTool,
          activeSnap: _activeSnap,
          selectedNote: _selectedNoteForLayer(_TrackLayer.drums),
          onSelectNote: _handleSelectNote,
          onNotesChanged: (List<Note> notes, Note? selected) =>
              _updateTrackNotes(_TrackLayer.drums, notes, selected),
        ),
      ),
      _TrackTabData(
        label: 'Ba',
        layer: _TrackLayer.bass,
        builder: () => PianoRollView(
          track: _section.bass,
          activeTool: _activeTool,
          activeSnap: _activeSnap,
          selectedNote: _selectedNoteForLayer(_TrackLayer.bass),
          onSelectNote: _handleSelectNote,
          onNotesChanged: (List<Note> notes, Note? selected) =>
              _updateTrackNotes(_TrackLayer.bass, notes, selected),
        ),
      ),
      _TrackTabData(
        label: 'Ch',
        builder: () => _ChordLaneView(chords: _section.chords),
      ),
      _TrackTabData(
        label: 'Me',
        layer: _TrackLayer.melody,
        builder: () => PianoRollView(
          track: _section.melody,
          activeTool: _activeTool,
          activeSnap: _activeSnap,
          selectedNote: _selectedNoteForLayer(_TrackLayer.melody),
          onSelectNote: _handleSelectNote,
          onNotesChanged: (List<Note> notes, Note? selected) =>
              _updateTrackNotes(_TrackLayer.melody, notes, selected),
        ),
      ),
    ];
  }

  Future<void> _openSnapSelector() async {
    final Snap? selected = await showModalBottomSheet<Snap>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: Snap.values
                .map(
                  (Snap snap) => ListTile(
                    leading: snap == _activeSnap
                        ? const Icon(Icons.check_circle, color: Colors.white70)
                        : const Icon(
                            Icons.circle_outlined,
                            color: Colors.white38,
                          ),
                    title: Text(snap.label),
                    subtitle: Text(
                      snap.description,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    onTap: () => Navigator.of(context).pop(snap),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (selected != null) {
      _handleSnapChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_TrackTabData> tabs = _buildTabs();
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
                    activeTool: _activeTool,
                    onToolSelected: _handleToolChanged,
                    activeSnap: _activeSnap,
                    onSnapPressed: _openSnapSelector,
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
                          onTabSelected: _handleTabSelected,
                          section: _section,
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
  const _TrackTabData({required this.label, required this.builder, this.layer});

  final String label;
  final Widget Function() builder;
  final _TrackLayer? layer;
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

class PianoRollView extends StatefulWidget {
  const PianoRollView({
    super.key,
    required this.track,
    required this.activeTool,
    required this.activeSnap,
    required this.selectedNote,
    required this.onSelectNote,
    required this.onNotesChanged,
  });

  final MidiTrack track;
  final Tool activeTool;
  final Snap activeSnap;
  final Note? selectedNote;
  final ValueChanged<Note?> onSelectNote;
  final void Function(List<Note> notes, Note? selectedNote) onNotesChanged;

  @override
  State<PianoRollView> createState() => _PianoRollViewState();
}

class _PianoRollViewState extends State<PianoRollView> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  List<Note> _notes = <Note>[];
  List<_VisualNote> _visualNotes = <_VisualNote>[];

  int? _draggingIndex;
  int _dragStartPitch = 0;
  double _dragAccumulatedDy = 0;

  int? _resizingIndex;
  double _resizeStartDuration = 0;
  double _resizeAccumulated = 0;

  @override
  void initState() {
    super.initState();
    _notes = List<Note>.from(widget.track.notes);
  }

  @override
  void didUpdateWidget(covariant PianoRollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.track.notes, widget.track.notes)) {
      _notes = List<Note>.from(widget.track.notes);
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Note> notes = _notes;

    int minPitch = notes.isEmpty
        ? 48
        : notes.map((Note n) => n.pitch).reduce(math.min) - 4;
    int maxPitch = notes.isEmpty
        ? 72
        : notes.map((Note n) => n.pitch).reduce(math.max) + 4;
    minPitch = minPitch.clamp(21, 100);
    maxPitch = math.max(maxPitch, minPitch + 12);
    maxPitch = math.min(maxPitch, 115);

    final int pitchSpan = maxPitch - minPitch + 1;
    final double contentHeight = pitchSpan * _kNoteHeight;

    double maxBeat = notes.isEmpty
        ? 4
        : notes.map((Note n) => n.startTime + n.duration).reduce(math.max);
    maxBeat = math.max(maxBeat, 4);
    final double contentWidth = math.max(
      context.size?.width ?? 0,
      (maxBeat + 4) * _kBeatWidth,
    );

    _visualNotes = <_VisualNote>[];

    Widget canvas = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (TapDownDetails details) =>
          _handleBackgroundTap(details, minPitch, maxPitch),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: _GridBackgroundPainter(
                minPitch: minPitch,
                maxPitch: maxPitch,
              ),
            ),
          ),
          ...notes.asMap().entries.map((MapEntry<int, Note> entry) {
            final int index = entry.key;
            final Note note = entry.value;
            final double left = note.startTime * _kBeatWidth;
            final double width = math.max(
              note.duration * _kBeatWidth,
              _kNoteHeight * 0.6,
            );
            final double top = (maxPitch - note.pitch) * _kNoteHeight;
            final Rect rect = Rect.fromLTWH(left, top, width, _kNoteHeight);
            _visualNotes.add(_VisualNote(index: index, note: note, rect: rect));
            final bool isSelected = identical(widget.selectedNote, note);
            final Color fillColor = isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.secondaryContainer;
            final Color handleColor = isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.7);

            return Positioned(
              left: left,
              top: top,
              width: width,
              height: _kNoteHeight,
              child: Stack(
                children: <Widget>[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleNoteTap(index),
                    onLongPressStart: (LongPressStartDetails details) =>
                        _showContextMenu(index, details.globalPosition),
                    onVerticalDragStart: widget.activeTool == Tool.select
                        ? (DragStartDetails details) =>
                              _startPitchDrag(index, note)
                        : null,
                    onVerticalDragUpdate: widget.activeTool == Tool.select
                        ? (DragUpdateDetails details) =>
                              _updatePitchDrag(details)
                        : null,
                    onVerticalDragEnd: widget.activeTool == Tool.select
                        ? (_) => _endPitchDrag()
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.9,
                                )
                              : Colors.black26,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${note.pitch}',
                        style: theme.textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: widget.activeTool == Tool.select
                          ? (_) => _startResize(index, note)
                          : null,
                      onHorizontalDragUpdate: widget.activeTool == Tool.select
                          ? (DragUpdateDetails details) =>
                                _updateResize(details)
                          : null,
                      onHorizontalDragEnd: widget.activeTool == Tool.select
                          ? (_) => _endResize()
                          : null,
                      child: Container(
                        width: 14,
                        decoration: BoxDecoration(
                          color: handleColor.withValues(alpha: 0.35),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.drag_handle_rounded,
                          size: 12,
                          color: handleColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            scrollDirection: Axis.vertical,
            child: SizedBox(
              width: contentWidth,
              height: contentHeight,
              child: canvas,
            ),
          ),
        ),
      ),
    );
  }

  void _notifyNotesChanged(Note? selectedNote) {
    widget.onNotesChanged(List<Note>.from(_notes), selectedNote);
  }

  void _handleNoteTap(int index) {
    if (widget.activeTool == Tool.write) {
      return;
    }
    final Note note = _notes[index];
    if (identical(widget.selectedNote, note)) {
      _deleteNoteAt(index);
    } else {
      widget.onSelectNote(note);
    }
  }

  void _handleBackgroundTap(
    TapDownDetails details,
    int minPitch,
    int maxPitch,
  ) {
    final Offset position = details.localPosition;
    final bool hitExisting = _visualNotes.any(
      (_VisualNote visual) => visual.rect.inflate(2).contains(position),
    );

    if (hitExisting) {
      return;
    }

    if (widget.activeTool == Tool.write) {
      final Note newNote = _createNoteAt(position, minPitch, maxPitch);
      setState(() {
        _notes.add(newNote);
        _notes.sort(_noteComparator);
      });
      _notifyNotesChanged(newNote);
      widget.onSelectNote(newNote);
    } else if (widget.activeTool == Tool.select) {
      widget.onSelectNote(null);
    }
  }

  Note _createNoteAt(Offset position, int minPitch, int maxPitch) {
    double start = position.dx / _kBeatWidth;
    start = math.max(0, start);
    start = _quantizeFloor(start, widget.activeSnap);

    double clampedY = position.dy.clamp(0, double.infinity);
    int pitchOffset = (clampedY / _kNoteHeight).floor();
    int pitch = (maxPitch - pitchOffset).clamp(0, 127);
    if (pitch < minPitch) {
      pitch = minPitch;
    } else if (pitch > maxPitch) {
      pitch = maxPitch;
    }

    final double duration = _defaultDuration(widget.activeSnap);

    return Note(
      pitch: pitch,
      startTime: _roundToDecimals(start, 3),
      duration: duration,
      velocity: 2,
    );
  }

  void _startPitchDrag(int index, Note note) {
    _draggingIndex = index;
    _dragStartPitch = note.pitch;
    _dragAccumulatedDy = 0;
    widget.onSelectNote(note);
  }

  void _updatePitchDrag(DragUpdateDetails details) {
    if (_draggingIndex == null) {
      return;
    }
    _dragAccumulatedDy += details.primaryDelta ?? 0;
    final int pitchDelta = (-_dragAccumulatedDy / _kNoteHeight).round();
    final int index = _draggingIndex!;
    final Note original = _notes[index];
    final int newPitch = (_dragStartPitch + pitchDelta).clamp(0, 127);
    if (newPitch == original.pitch) {
      return;
    }
    final Note updated = original.copyWith(pitch: newPitch);
    setState(() {
      _notes[index] = updated;
    });
    _notifyNotesChanged(updated);
    widget.onSelectNote(updated);
  }

  void _endPitchDrag() {
    _draggingIndex = null;
    _dragAccumulatedDy = 0;
  }

  void _startResize(int index, Note note) {
    _resizingIndex = index;
    _resizeStartDuration = note.duration;
    _resizeAccumulated = 0;
    widget.onSelectNote(note);
  }

  void _updateResize(DragUpdateDetails details) {
    if (_resizingIndex == null) {
      return;
    }
    _resizeAccumulated += (details.primaryDelta ?? 0) / _kBeatWidth;
    final int index = _resizingIndex!;
    final Note original = _notes[index];
    double newDuration = _resizeStartDuration + _resizeAccumulated;
    newDuration = _quantizeDuration(newDuration, widget.activeSnap);
    if ((newDuration - original.duration).abs() < 0.001) {
      return;
    }
    final Note updated = original.copyWith(duration: newDuration);
    setState(() {
      _notes[index] = updated;
    });
    _notifyNotesChanged(updated);
    widget.onSelectNote(updated);
  }

  void _endResize() {
    _resizingIndex = null;
    _resizeAccumulated = 0;
  }

  void _showContextMenu(int index, Offset globalPosition) async {
    final Note note = _notes[index];
    widget.onSelectNote(note);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      Offset.zero & overlay.size,
    );

    final String? action = await showMenu<String>(
      context: context,
      position: position,
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'copy', child: Text('[ Copy ]')),
        const PopupMenuItem<String>(
          value: 'lengthen',
          child: Text('[ Lengthen (→) ]'),
        ),
        const PopupMenuItem<String>(
          value: 'shorten',
          child: Text('[ Shorten (←) ]'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'delete', child: Text('[ Delete ]')),
      ],
    );

    switch (action) {
      case 'copy':
        _copyNoteAt(index);
        break;
      case 'lengthen':
        _resizeByStep(index, increase: true);
        break;
      case 'shorten':
        _resizeByStep(index, increase: false);
        break;
      case 'delete':
        _deleteNoteAt(index);
        break;
      default:
        break;
    }
  }

  void _copyNoteAt(int index) {
    final Note original = _notes[index];
    double start = original.startTime + original.duration;
    start = _quantize(start, widget.activeSnap);
    final Note duplicate = Note(
      pitch: original.pitch,
      startTime: start,
      duration: original.duration,
      velocity: original.velocity,
    );
    setState(() {
      _notes.add(duplicate);
      _notes.sort(_noteComparator);
    });
    _notifyNotesChanged(duplicate);
    widget.onSelectNote(duplicate);
  }

  void _resizeByStep(int index, {required bool increase}) {
    final Note original = _notes[index];
    final double step = _snapStep(widget.activeSnap);
    double newDuration = increase
        ? original.duration + step
        : original.duration - step;
    newDuration = _quantizeDuration(newDuration, widget.activeSnap);
    if ((newDuration - original.duration).abs() < 0.001) {
      return;
    }
    final Note updated = original.copyWith(duration: newDuration);
    setState(() {
      _notes[index] = updated;
    });
    _notifyNotesChanged(updated);
    widget.onSelectNote(updated);
  }

  void _deleteNoteAt(int index) {
    setState(() {
      _notes.removeAt(index);
    });
    _notifyNotesChanged(null);
    widget.onSelectNote(null);
  }
}

class _VisualNote {
  const _VisualNote({
    required this.index,
    required this.note,
    required this.rect,
  });

  final int index;
  final Note note;
  final Rect rect;
}

class _GridBackgroundPainter extends CustomPainter {
  const _GridBackgroundPainter({
    required this.minPitch,
    required this.maxPitch,
  });

  final int minPitch;
  final int maxPitch;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint beatPaint = Paint()
      ..color = const Color(0x1FFFFFFF)
      ..strokeWidth = 1;
    final Paint subdivisionPaint = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += _kBeatWidth) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), beatPaint);
      for (int i = 1; i < 4; i++) {
        final double subdivisionX = x + (_kBeatWidth / 4) * i;
        canvas.drawLine(
          Offset(subdivisionX, 0),
          Offset(subdivisionX, size.height),
          subdivisionPaint,
        );
      }
    }

    for (int pitch = minPitch; pitch <= maxPitch; pitch++) {
      final double y = (maxPitch - pitch + 1) * _kNoteHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), subdivisionPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChordLaneView extends StatelessWidget {
  const _ChordLaneView({required this.chords});

  final List<ChordEntry> chords;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (chords.isEmpty) {
      return Center(
        child: Text(
          'コードが未設定です',
          style: theme.textTheme.titleMedium!.copyWith(color: Colors.white54),
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
          title: Text(entry.chordName, style: theme.textTheme.titleMedium),
          subtitle: entry.lyric != null
              ? Text(
                  entry.lyric!,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: Colors.white70,
                  ),
                )
              : null,
          trailing: Text(
            '${entry.startTime.toStringAsFixed(1)} 拍',
            style: theme.textTheme.bodySmall!.copyWith(color: Colors.white70),
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
  const _TrackLeftColumn({
    required this.onBack,
    required this.activeTool,
    required this.onToolSelected,
    required this.activeSnap,
    required this.onSnapPressed,
  });

  final VoidCallback onBack;
  final Tool activeTool;
  final ValueChanged<Tool> onToolSelected;
  final Snap activeSnap;
  final VoidCallback onSnapPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    ButtonStyle toolStyle(Tool tool) {
      final bool isActive = activeTool == tool;
      return FilledButton.styleFrom(
        backgroundColor: isActive ? theme.colorScheme.primary : null,
        foregroundColor: isActive ? theme.colorScheme.onPrimary : null,
      );
    }

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
          _ControlButton(
            label: '[ Select ]',
            icon: Icons.touch_app,
            onPressed: () => onToolSelected(Tool.select),
            style: toolStyle(Tool.select),
          ),
          const SizedBox(height: 12),
          _ControlButton(
            label: '[ Write ]',
            icon: Icons.edit,
            onPressed: () => onToolSelected(Tool.write),
            style: toolStyle(Tool.write),
          ),
          const SizedBox(height: 12),
          _ControlButton(
            label: '[ Snap: ${activeSnap.label} ]',
            icon: Icons.grid_view,
            onPressed: onSnapPressed,
          ),
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
