import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controllers/mutate_workflow_controller.dart';
import '../../models/note.dart';
import '../../models/snap_mode.dart';
import '../../state/piano_roll_controller.dart';
import '../../state/song_state.dart';
import '../../state/undo_manager.dart';
import '../widgets/mutate_button.dart';

const double _kTimelineBeats = 16.0;
const double _kNoteRowHeight = 36.0;
const int _kTopPitch = 84;

class TrackViewScreen extends StatelessWidget {
  const TrackViewScreen({
    super.key,
    required this.mutateController,
    required this.pianoRollController,
    required this.songState,
    required this.undoManager,
    this.onBackPressed,
    this.onSavePressed,
    this.onHumPressed,
  });

  final MutateWorkflowController mutateController;
  final PianoRollController pianoRollController;
  final SongState songState;
  final UndoManager undoManager;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSavePressed;
  final VoidCallback? onHumPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 568dp × 320dp を基準にレイアウト最適化
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final sideBarWidth = math.min(screenWidth * 0.15, 80.0); // サイドバー幅を縮小
        final centerWidth = screenWidth - (sideBarWidth * 2);
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: sideBarWidth,
              child: _LeftThumbColumn(
                controller: mutateController,
                pianoRollController: pianoRollController,
                songState: songState,
                onBackPressed: onBackPressed,
                onHumPressed: onHumPressed,
              ),
            ),
            Expanded(
              child: _PianoRollArea(
                songState: songState,
                pianoRollController: pianoRollController,
                mutateController: mutateController,
              ),
            ),
            SizedBox(
              width: sideBarWidth,
              child: _RightThumbColumn(
                undoManager: undoManager,
                songState: songState,
                pianoRollController: pianoRollController,
                onSavePressed: onSavePressed,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LeftThumbColumn extends StatelessWidget {
  const _LeftThumbColumn({
    required this.controller,
    required this.pianoRollController,
    required this.songState,
    this.onBackPressed,
    this.onHumPressed,
  });

  final MutateWorkflowController controller;
  final PianoRollController pianoRollController;
  final SongState songState;
  final VoidCallback? onBackPressed;
  final VoidCallback? onHumPressed;

  @override
  Widget build(BuildContext context) {
    final listenable =
        Listenable.merge([controller, pianoRollController, songState]);
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final canCopy = controller.canCopy;
        final canPaste = controller.canPaste;
        final canDelete = controller.canDelete;
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ThumbButton(
                    label: 'BACK',
                    icon: Icons.arrow_back,
                    onPressed: onBackPressed,
                  ),
                  const SizedBox(height: 4),
                  _ThumbButton(
                    label: 'SEL',
                    icon: Icons.select_all,
                    isActive: pianoRollController.isSelectToolActive,
                    onPressed: () =>
                        pianoRollController.editorTool = EditorTool.select,
                  ),
                  const SizedBox(height: 4),
                  _ThumbButton(
                    label: 'DRAW',
                    icon: Icons.brush,
                    isActive: pianoRollController.isDrawToolActive,
                    onPressed: () =>
                        pianoRollController.editorTool = EditorTool.draw,
                  ),
                  const SizedBox(height: 8),
                  _SnapSelector(pianoRollController: pianoRollController),
                  const SizedBox(height: 8),
                  _ThumbButton(
                    label: 'OCT+',
                    icon: Icons.arrow_upward,
                    onPressed: () {
                      pianoRollController.octaveOffset += 12;
                    },
                  ),
                  const SizedBox(height: 4),
                  _ThumbButton(
                    label: 'OCT-',
                    icon: Icons.arrow_downward,
                    onPressed: () {
                      pianoRollController.octaveOffset -= 12;
                    },
                  ),
                  if (canCopy || canPaste || canDelete) ...[
                    const SizedBox(height: 8),
                    if (canCopy)
                      _ThumbButton(
                        label: 'CPY',
                        icon: Icons.copy,
                        onPressed: controller.copySelection,
                      ),
                    if (canCopy) const SizedBox(height: 4),
                    if (canCopy)
                      _ThumbButton(
                        label: 'CUT',
                        icon: Icons.content_cut,
                        onPressed: controller.cutSelection,
                      ),
                    if (canDelete) const SizedBox(height: 4),
                    if (canDelete)
                      _ThumbButton(
                        label: 'DEL',
                        icon: Icons.delete,
                        onPressed: controller.deleteSelection,
                      ),
                    if (canPaste) const SizedBox(height: 4),
                    if (canPaste)
                      _ThumbButton(
                        label: 'PST',
                        icon: Icons.paste,
                        onPressed: controller.pasteClipboard,
                      ),
                  ],
                  const SizedBox(height: 8),
                  MutateButton(controller: controller),
                  const SizedBox(height: 8),
                  _ThumbButton(
                    label: 'HUM',
                    icon: Icons.mic,
                    onPressed: onHumPressed,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RightThumbColumn extends StatelessWidget {
  const _RightThumbColumn({
    required this.undoManager,
    required this.songState,
    required this.pianoRollController,
    this.onSavePressed,
  });

  final UndoManager undoManager;
  final SongState songState;
  final PianoRollController pianoRollController;
  final VoidCallback? onSavePressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ThumbButton(
                label: pianoRollController.guideVisible ? 'GUIDE ON' : 'GUIDE',
                icon: Icons.visibility,
                isActive: pianoRollController.guideVisible,
                onPressed: () {
                  pianoRollController.guideVisible = !pianoRollController.guideVisible;
                },
              ),
              const SizedBox(height: 4),
              _ThumbButton(label: 'SAVE', icon: Icons.save, onPressed: onSavePressed),
              const SizedBox(height: 4),
              _ThumbButton(
                label: songState.metronomeEnabled ? 'METRO ON' : 'METRO',
                icon: Icons.timer,
                isActive: songState.metronomeEnabled,
                onPressed: () {
                  songState.toggleMetronome();
                },
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: undoManager,
                builder: (context, _) {
                  return Column(
                    children: [
                      _ThumbButton(
                        label: 'REDO',
                        icon: Icons.redo,
                        onPressed: undoManager.canRedo ? undoManager.redo : null,
                      ),
                      const SizedBox(height: 4),
                      _ThumbButton(
                        label: 'UNDO',
                        icon: Icons.undo,
                        onPressed: undoManager.canUndo ? undoManager.undo : null,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              _ThumbButton(
                label: songState.isPlaying ? 'STOP' : 'PLAY',
                icon: songState.isPlaying ? Icons.stop : Icons.play_arrow,
                onPressed: () {
                  songState.togglePlay();
                },
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbButton extends StatelessWidget {
  const _ThumbButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final Color backgroundColor;
    final Color foregroundColor;
    if (!enabled) {
      backgroundColor = scheme.surfaceVariant;
      foregroundColor = scheme.onSurface.withOpacity(0.4);
    } else if (isPrimary) {
      backgroundColor = scheme.primary;
      foregroundColor = scheme.onPrimary;
    } else if (isActive) {
      backgroundColor = scheme.primaryContainer;
      foregroundColor = scheme.onPrimaryContainer;
    } else {
      backgroundColor = scheme.surface;
      foregroundColor = scheme.onSurface;
    }

    final button = ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      onPressed: onPressed,
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: scheme.surfaceVariant,
        disabledForegroundColor: scheme.onSurface.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(0, 36),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: button,
    );
  }
}

class _SnapSelector extends StatelessWidget {
  const _SnapSelector({
    required this.pianoRollController,
  });

  final PianoRollController pianoRollController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.grid_on, size: 16),
        label: Text(
          'SNAP: ${pianoRollController.snapMode.shortLabel}',
          style: const TextStyle(fontSize: 11),
        ),
        onPressed: () => _showSnapSheet(context),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _showSnapSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in SnapMode.values)
                ListTile(
                  title: Text(mode.label),
                  trailing: mode == pianoRollController.snapMode
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    pianoRollController.snapMode = mode;
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayheadControl extends StatelessWidget {
  const _PlayheadControl({
    required this.songState,
    required this.pianoRollController,
  });

  final SongState songState;
  final PianoRollController pianoRollController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: songState,
      builder: (context, _) {
        final clamped = songState.playheadBeat.clamp(0.0, 16.0);
        final sliderValue = (clamped as num).toDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PH: ${songState.playheadBeat.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Slider(
                value: sliderValue,
                min: 0,
                max: 16,
                divisions: 64,
                label: sliderValue.toStringAsFixed(2),
                onChanged: (value) {
                  final snapped = pianoRollController.snapMode == SnapMode.free
                      ? value
                      : pianoRollController.snapBeat(value);
                  songState.playheadBeat = snapped;
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PianoRollArea extends StatelessWidget {
  const _PianoRollArea({
    required this.songState,
    required this.pianoRollController,
    required this.mutateController,
  });

  final SongState songState;
  final PianoRollController pianoRollController;
  final MutateWorkflowController mutateController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TrackHeader(
          songState: songState,
          pianoRollController: pianoRollController,
          mutateController: mutateController,
        ),
        _PlayheadControl(
          songState: songState,
          pianoRollController: pianoRollController,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double timelineBeats = _kTimelineBeats;
              final double timelineWidth = constraints.maxWidth;
              final double viewHeight = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : _kNoteRowHeight * 16;
              return _InteractivePianoRoll(
                songState: songState,
                pianoRollController: pianoRollController,
                mutateController: mutateController,
                timelineBeats: timelineBeats,
                timelineWidth: timelineWidth,
                viewHeight: viewHeight,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader({
    required this.songState,
    required this.pianoRollController,
    required this.mutateController,
  });

  final SongState songState;
  final PianoRollController pianoRollController;
  final MutateWorkflowController mutateController;

  @override
  Widget build(BuildContext context) {
    final tracks = songState.tracks;
    if (tracks.isEmpty) {
      return const SizedBox.shrink();
    }
    final selectedTrackId = pianoRollController.trackId;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ToggleButtons(
              isSelected: tracks
                  .map((track) => track.id == selectedTrackId)
                  .toList(growable: false),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
              children: tracks
                  .map(
                    (track) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        (track.name.length >= 2
                                ? track.name.substring(0, 2)
                                : track.name)
                            .toUpperCase(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onPressed: (index) {
                if (index < 0 || index >= tracks.length) return;
                final track = tracks[index];
                if (track.id == pianoRollController.trackId) return;
                mutateController.cancelPreview();
                pianoRollController.trackId = track.id;
                pianoRollController.contextType = track.contextType;
                pianoRollController.clearSelection();
                pianoRollController.clearPreviewNotes();
              },
            ),
            AnimatedBuilder(
              animation: pianoRollController,
              builder: (context, _) {
                final currentTrack =
                    songState.trackById(pianoRollController.trackId);
                return Text(
                  currentTrack == null
                      ? 'TRK: ${pianoRollController.trackId}'
                      : 'TRK: ${currentTrack.name} | CTX: ${currentTrack.contextType}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 本物のグラフィカルなピアノロールウィジェット（CustomPaint使用）
class _InteractivePianoRoll extends StatefulWidget {
  const _InteractivePianoRoll({
    required this.songState,
    required this.pianoRollController,
    required this.mutateController,
    required this.timelineBeats,
    required this.timelineWidth,
    required this.viewHeight,
  });

  final SongState songState;
  final PianoRollController pianoRollController;
  final MutateWorkflowController mutateController;
  final double timelineBeats;
  final double timelineWidth;
  final double viewHeight;

  @override
  State<_InteractivePianoRoll> createState() => _InteractivePianoRollState();
}

class _InteractivePianoRollState extends State<_InteractivePianoRoll> {
  Note? _resizingNote;
  double _dragStartDx = 0.0;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // スクロール中は何もしない
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = Listenable.merge([
      widget.songState,
      widget.pianoRollController,
      widget.mutateController,
    ]);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Listener(
          onPointerDown: (event) {
            // タップイベントを処理
            final local = event.localPosition;
            final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
            final adjustedX = local.dx + scrollOffset;
            final beat = _pixelToBeat(adjustedX);
            final pitch = _pixelToPitch(local.dy) + widget.pianoRollController.octaveOffset;

            if (widget.pianoRollController.isDrawToolActive &&
                !widget.mutateController.isBusy) {
              // 書き込みモード: ノートを作成（オクターブオフセットを適用）
              final clampedPitch = pitch.clamp(0, 127);
              widget.mutateController.createNoteAt(beat, clampedPitch);
            } else if (widget.pianoRollController.isSelectToolActive) {
              // 選択モード: タップした位置のノートを選択/解除
              final notes = widget.songState.notesForTrack(
                widget.pianoRollController.trackId,
              );
              final tappedNote = _findNoteAtPosition(notes, beat, pitch);
              if (tappedNote != null) {
                final current = widget.pianoRollController.selectedNotes.toList();
                if (current.any((n) => n.id == tappedNote.id)) {
                  current.removeWhere((n) => n.id == tappedNote.id);
                } else {
                  current.add(tappedNote);
                }
                widget.pianoRollController.updateSelection(current);
              } else {
                widget.pianoRollController.clearSelection();
              }
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (notification) {
                _snapToBar();
                return true;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: CustomPaint(
                  painter: PianoRollPainter(
                    songState: widget.songState,
                    pianoRollController: widget.pianoRollController,
                    timelineBeats: widget.timelineBeats,
                    timelineWidth: widget.timelineWidth,
                  ),
                  size: Size(widget.timelineWidth, widget.viewHeight),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  void _snapToBar() {
    // スクロール終了時に小節単位でスナップ
    final scrollOffset = _scrollController.offset;
    final beatPerPixel = widget.timelineWidth / widget.timelineBeats;
    final currentBeat = scrollOffset / beatPerPixel;
    final snappedBeat = (currentBeat / 4.0).round() * 4.0; // 小節単位（4拍）でスナップ
    final snappedOffset = snappedBeat * beatPerPixel;
    _scrollController.animateTo(
      snappedOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }


  void _handlePanStart(DragStartDetails details) {
    if (!widget.pianoRollController.isDrawToolActive) return;
    final local = details.localPosition;
    final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final adjustedX = local.dx + scrollOffset;
    final beat = _pixelToBeat(adjustedX);
    final pitch = _pixelToPitch(local.dy);
    final notes = widget.songState.notesForTrack(
      widget.pianoRollController.trackId,
    );
    final note = _findNoteAtPosition(notes, beat, pitch);
    if (note != null) {
      _resizingNote = note;
      _dragStartDx = local.dx;
      widget.mutateController.startNoteResize(note);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_resizingNote == null || !widget.pianoRollController.isDrawToolActive) {
      return;
    }
    final currentDx = details.localPosition.dx;
    final deltaDx = currentDx - _dragStartDx;
    final beatPerPixel = widget.timelineBeats / widget.timelineWidth;
    final deltaBeats = beatPerPixel * deltaDx;
    final rawEndBeat = _resizingNote!.startBeat + _resizingNote!.duration + deltaBeats;
    // スナップを適用して長さを制限
    final snappedEndBeat = widget.pianoRollController.snapBeat(rawEndBeat);
    final snappedDuration = math.max(0.125, snappedEndBeat - _resizingNote!.startBeat);
    final clampedEndBeat = _resizingNote!.startBeat + snappedDuration;
    final updated = widget.mutateController.updateNoteResize(
      _resizingNote!,
      clampedEndBeat,
    );
    if (updated != null) {
      setState(() {
        _resizingNote = updated;
        _dragStartDx = currentDx; // ドラッグ開始位置を更新
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_resizingNote != null) {
      widget.mutateController.endNoteResize(_resizingNote!);
      _resizingNote = null;
    }
  }

  double _pixelToBeat(double x) {
    return (x / widget.timelineWidth) * widget.timelineBeats;
  }

  int _pixelToPitch(double y) {
    final row = (y / _kNoteRowHeight).floor();
    return (_kTopPitch - row).clamp(0, 127);
  }

  Note? _findNoteAtPosition(List<Note> notes, double beat, int pitch) {
    const tolerance = 0.5; // 拍の許容範囲
    for (final note in notes) {
      final pitchMatch = note.pitch == pitch;
      final beatMatch = beat >= note.startBeat - tolerance &&
          beat <= note.startBeat + note.duration + tolerance;
      if (pitchMatch && beatMatch) {
        return note;
      }
    }
    return null;
  }
}

/// ピアノロールの描画を担当するCustomPainter
class PianoRollPainter extends CustomPainter {
  PianoRollPainter({
    required this.songState,
    required this.pianoRollController,
    required this.timelineBeats,
    required this.timelineWidth,
  });

  final SongState songState;
  final PianoRollController pianoRollController;
  final double timelineBeats;
  final double timelineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final theme = _getThemeColors();
    
    // 背景を描画
    _drawBackground(canvas, size, theme);
    
    // グリッドを描画
    _drawGrid(canvas, size, theme);
    
    // ノートを描画
    _drawNotes(canvas, size, theme);
    
    // 再生ヘッドを描画
    _drawPlayhead(canvas, size, theme);
  }

  void _drawBackground(Canvas canvas, Size size, _ThemeColors theme) {
    final backgroundPaint = Paint()..color = theme.backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
  }

  void _drawGrid(Canvas canvas, Size size, _ThemeColors theme) {
    if (!pianoRollController.guideVisible) {
      // ガイドが無効な場合は背景のみ描画
      return;
    }
    
    final beatPerPixel = timelineWidth == 0 ? 0.0 : timelineBeats / timelineWidth;
    
    // 小節線（太線、4拍ごと）
    final barPaint = Paint()
      ..color = theme.barLineColor
      ..strokeWidth = 2.0;
    for (double beat = 0; beat <= timelineBeats; beat += 4.0) {
      final x = (beat / timelineBeats) * timelineWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), barPaint);
    }
    
    // 拍線（細線、1拍ごと）
    final beatPaint = Paint()
      ..color = theme.beatLineColor
      ..strokeWidth = 1.0;
    for (double beat = 0; beat <= timelineBeats; beat += 1.0) {
      if (beat % 4 != 0) { // 小節線と重複しないように
        final x = (beat / timelineBeats) * timelineWidth;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), beatPaint);
      }
    }
    
    // グリッド線（16分音符、SnapMode.gridの場合のみ）
    if (pianoRollController.snapMode == SnapMode.grid) {
      final gridPaint = Paint()
        ..color = theme.gridLineColor
        ..strokeWidth = 0.5;
      for (double beat = 0; beat <= timelineBeats; beat += 0.25) {
        if (beat % 1 != 0 && beat % 4 != 0) { // 拍線・小節線と重複しないように
          final x = (beat / timelineBeats) * timelineWidth;
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
        }
      }
    }
    
    // ピッチ行の横線
    final rowPaint = Paint()
      ..color = theme.rowLineColor
      ..strokeWidth = 0.5;
    final rows = (size.height / _kNoteRowHeight).ceil();
    for (int row = 0; row <= rows; row++) {
      final y = row * _kNoteRowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rowPaint);
    }
  }

  void _drawNotes(Canvas canvas, Size size, _ThemeColors theme) {
    final notes = songState.notesForTrack(pianoRollController.trackId);
    final selectedIds = pianoRollController.selectedNotes
        .map((note) => note.id)
        .toSet();
    final previewIds = pianoRollController.previewNotes
            ?.map((note) => note.id)
            .toSet() ??
        const <String>{};
    
    final beatPerPixel = timelineWidth == 0 ? 0.0 : timelineWidth / timelineBeats;
    
    for (final note in notes) {
      final isSelected = selectedIds.contains(note.id);
      final isPreview = previewIds.contains(note.id);
      
      final pitch = note.pitch;
      final row = _kTopPitch - pitch;
      final y = row * _kNoteRowHeight;
      final x = (note.startBeat / timelineBeats) * timelineWidth;
      final width = note.duration * beatPerPixel;
      
      final rect = Rect.fromLTWH(
        x,
        y,
        width,
        _kNoteRowHeight,
      );
      
      // ノートの背景色
      final backgroundColor = isPreview
          ? theme.previewNoteColor
          : isSelected
              ? theme.selectedNoteColor
              : theme.noteColor;
      
      final notePaint = Paint()..color = backgroundColor;
      canvas.drawRect(rect, notePaint);
      
      // 選択されている場合は枠線を描画
      if (isSelected) {
        final borderPaint = Paint()
          ..color = theme.selectedBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  void _drawPlayhead(Canvas canvas, Size size, _ThemeColors theme) {
    final playheadBeat = songState.playheadBeat.clamp(0.0, timelineBeats);
    final x = (playheadBeat / timelineBeats) * timelineWidth;
    
    final playheadPaint = Paint()
      ..color = theme.playheadColor
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      playheadPaint,
    );
  }

  @override
  bool shouldRepaint(PianoRollPainter oldDelegate) {
    // AnimatedBuilderが既に再描画をトリガーしているので、
    // ここではタイムラインのサイズが変わった場合のみ再描画が必要
    // ただし、songStateやpianoRollControllerの内容が変わった場合も
    // AnimatedBuilderが再描画をトリガーするため、基本的には常にtrueを返す
    // より細かい最適化として、実際に変更があった場合のみtrueを返す
    if (oldDelegate.timelineBeats != timelineBeats ||
        oldDelegate.timelineWidth != timelineWidth) {
      return true;
    }
    
    // 再生ヘッドの位置が変わった場合
    if ((oldDelegate.songState.playheadBeat - songState.playheadBeat).abs() > 1e-6) {
      return true;
    }
    
    // ノートの数が変わった場合
    final oldNotes = oldDelegate.songState.notesForTrack(pianoRollController.trackId);
    final newNotes = songState.notesForTrack(pianoRollController.trackId);
    if (oldNotes.length != newNotes.length) {
      return true;
    }
    
    // 選択状態が変わった場合
    if (oldDelegate.pianoRollController.selectedNotes.length !=
        pianoRollController.selectedNotes.length) {
      return true;
    }
    
    // プレビュー状態が変わった場合
    final oldPreviewCount = oldDelegate.pianoRollController.previewNotes?.length ?? 0;
    final newPreviewCount = pianoRollController.previewNotes?.length ?? 0;
    if (oldPreviewCount != newPreviewCount) {
      return true;
    }
    
    // それ以外の場合は、AnimatedBuilderが再描画をトリガーするのでfalseを返す
    // ただし、ノートの内容が変わった場合も検出する必要があるため、
    // より細かい比較が必要な場合は常にtrueを返す方が安全
    return false;
  }

  _ThemeColors _getThemeColors() {
    // Material Designのテーマカラーを使用
    // 実際のテーマにアクセスするには、BuildContextが必要ですが、
    // CustomPainterでは直接アクセスできないため、デフォルトカラーを使用
    return _ThemeColors(
      backgroundColor: const Color(0xFFFAFAFA),
      barLineColor: const Color(0xFF424242),
      beatLineColor: const Color(0xFF757575),
      gridLineColor: const Color(0xFFBDBDBD),
      rowLineColor: const Color(0xFFE0E0E0),
      noteColor: const Color(0xFF2196F3),
      selectedNoteColor: const Color(0xFF1976D2),
      selectedBorderColor: const Color(0xFF0D47A1),
      previewNoteColor: const Color(0x66FF9800), // 半透明オレンジ
      playheadColor: Colors.red,
    );
  }
}

class _ThemeColors {
  _ThemeColors({
    required this.backgroundColor,
    required this.barLineColor,
    required this.beatLineColor,
    required this.gridLineColor,
    required this.rowLineColor,
    required this.noteColor,
    required this.selectedNoteColor,
    required this.selectedBorderColor,
    required this.previewNoteColor,
    required this.playheadColor,
  });

  final Color backgroundColor;
  final Color barLineColor;
  final Color beatLineColor;
  final Color gridLineColor;
  final Color rowLineColor;
  final Color noteColor;
  final Color selectedNoteColor;
  final Color selectedBorderColor;
  final Color previewNoteColor;
  final Color playheadColor;
}
