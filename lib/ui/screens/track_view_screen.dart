import 'package:flutter/material.dart';

import '../../controllers/mutate_workflow_controller.dart';
import '../../models/snap_mode.dart';
import '../../state/piano_roll_controller.dart';
import '../../state/song_state.dart';
import '../../state/undo_manager.dart';
import '../widgets/mutate_button.dart';

class TrackViewScreen extends StatelessWidget {
  const TrackViewScreen({
    super.key,
    required this.mutateController,
    required this.pianoRollController,
    required this.songState,
    required this.undoManager,
  });

  final MutateWorkflowController mutateController;
  final PianoRollController pianoRollController;
  final SongState songState;
  final UndoManager undoManager;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: constraints.maxWidth * 0.15,
                child: _LeftThumbColumn(
                  controller: mutateController,
                  pianoRollController: pianoRollController,
                  songState: songState,
                ),
            ),
            Expanded(
              flex: 7,
              child: _PianoRollArea(
                songState: songState,
                pianoRollController: pianoRollController,
                mutateController: mutateController,
              ),
            ),
            SizedBox(
              width: constraints.maxWidth * 0.15,
              child: _RightThumbColumn(undoManager: undoManager),
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
  });

  final MutateWorkflowController controller;
  final PianoRollController pianoRollController;
  final SongState songState;

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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ThumbButton(
                  label: '← 戻る',
                  icon: Icons.arrow_back,
                  onPressed: () {},
                ),
                const SizedBox(height: 8),
                _ThumbButton(
                  label: '選択',
                  icon: Icons.select_all,
                  isActive: pianoRollController.isSelectToolActive,
                  onPressed: () =>
                      pianoRollController.editorTool = EditorTool.select,
                ),
                const SizedBox(height: 8),
                _ThumbButton(
                  label: '書き込み',
                  icon: Icons.brush,
                  isActive: pianoRollController.isDrawToolActive,
                  onPressed: () =>
                      pianoRollController.editorTool = EditorTool.draw,
                ),
                const SizedBox(height: 12),
                _SnapSelector(pianoRollController: pianoRollController),
                const SizedBox(height: 12),
                _ThumbButton(
                  label: 'オクターブ ↑',
                  icon: Icons.arrow_upward,
                  onPressed: () {},
                ),
                const SizedBox(height: 8),
                _ThumbButton(
                  label: 'オクターブ ↓',
                  icon: Icons.arrow_downward,
                  onPressed: () {},
                ),
                if (canCopy || canPaste || canDelete) ...[
                  const SizedBox(height: 16),
                  if (canCopy)
                    _ThumbButton(
                      label: 'コピー',
                      icon: Icons.copy,
                      onPressed: controller.copySelection,
                    ),
                  if (canCopy) const SizedBox(height: 8),
                  if (canCopy)
                    _ThumbButton(
                      label: 'カット',
                      icon: Icons.content_cut,
                      onPressed: controller.cutSelection,
                    ),
                  if (canDelete) const SizedBox(height: 8),
                  if (canDelete)
                    _ThumbButton(
                      label: '削除',
                      icon: Icons.delete,
                      onPressed: controller.deleteSelection,
                    ),
                  if (canPaste) const SizedBox(height: 8),
                  if (canPaste)
                    _ThumbButton(
                      label: 'ペースト',
                      icon: Icons.paste,
                      onPressed: controller.pasteClipboard,
                    ),
                ],
                const Spacer(),
                MutateButton(controller: controller),
                const SizedBox(height: 12),
                _ThumbButton(
                  label: '鼻歌 (Hum)',
                  icon: Icons.mic,
                  onPressed: () {},
                ),
              ],
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
  });

  final UndoManager undoManager;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ThumbButton(label: 'ガイド', icon: Icons.visibility, onPressed: () {}),
            _ThumbButton(label: '保存', icon: Icons.save, onPressed: () {}),
            _ThumbButton(label: 'メトロノーム', icon: Icons.timer, onPressed: () {}),
            AnimatedBuilder(
              animation: undoManager,
              builder: (context, _) {
                return Column(
                  children: [
                    _ThumbButton(
                      label: 'Redo',
                      icon: Icons.redo,
                      onPressed: undoManager.canRedo ? undoManager.redo : null,
                    ),
                    _ThumbButton(
                      label: 'Undo',
                      icon: Icons.undo,
                      onPressed: undoManager.canUndo ? undoManager.undo : null,
                    ),
                  ],
                );
              },
            ),
            const Spacer(),
            _ThumbButton(
              label: '再生 / 停止',
              icon: Icons.play_arrow,
              onPressed: () {},
              isPrimary: true,
            ),
          ],
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
      icon: Icon(icon),
      onPressed: onPressed,
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: scheme.surfaceVariant,
        disabledForegroundColor: scheme.onSurface.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
      height: 48,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.grid_on),
        label: Text('スナップ: ${pianoRollController.snapMode.label}'),
        onPressed: () => _showSnapSheet(context),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '再生ヘッド: ${songState.playheadBeat.toStringAsFixed(2)} 拍',
                style: Theme.of(context).textTheme.bodyMedium,
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
          child: _PianoRollMock(
            songState: songState,
            pianoRollController: pianoRollController,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ToggleButtons(
              isSelected: tracks
                  .map((track) => track.id == selectedTrackId)
                  .toList(growable: false),
              children: tracks
                  .map(
                    (track) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        (track.name.length >= 2
                                ? track.name.substring(0, 2)
                                : track.name)
                            .toUpperCase(),
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
                      ? 'トラック: ${pianoRollController.trackId}'
                      : 'トラック: ${currentTrack.name} | コンテキスト: ${currentTrack.contextType}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PianoRollMock extends StatelessWidget {
  const _PianoRollMock({
    required this.songState,
    required this.pianoRollController,
  });

  final SongState songState;
  final PianoRollController pianoRollController;

  @override
  Widget build(BuildContext context) {
    final animation = Listenable.merge([songState, pianoRollController]);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final notes = songState.notesForTrack(pianoRollController.trackId);
        final selectedIds =
            pianoRollController.selectedNotes.map((note) => note.id).toSet();
        final previewIds =
            pianoRollController.previewNotes?.map((note) => note.id).toSet() ??
                const <String>{};

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (context, index) {
              final note = notes[index];
              final isSelected = selectedIds.contains(note.id);
              final isPreview = previewIds.contains(note.id);
              final playhead = songState.playheadBeat;
              final isPlayheadActive =
                  playhead >= note.startBeat &&
                  playhead < note.startBeat + note.duration;
              final Color backgroundColor;
              if (isPreview) {
                backgroundColor = Colors.orange.withOpacity(0.4);
              } else if (isSelected) {
                backgroundColor =
                    Theme.of(context).colorScheme.primary.withOpacity(0.2);
              } else if (isPlayheadActive) {
                backgroundColor =
                    Theme.of(context).colorScheme.secondaryContainer;
              } else {
                backgroundColor =
                    Theme.of(context).colorScheme.surfaceVariant;
              }
              return GestureDetector(
                onTap: () {
                  final current = pianoRollController.selectedNotes.toList();
                  if (isSelected) {
                    current.removeWhere((n) => n.id == note.id);
                  } else {
                    current.add(note);
                  }
                  pianoRollController.updateSelection(current);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : isPlayheadActive
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Note ${note.id} | Pitch ${note.pitch}'),
                      Text(
                        'Start ${note.startBeat.toStringAsFixed(2)} / Len ${note.duration.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              );
          },
        );
      },
    );
  }
}
