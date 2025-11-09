import 'package:flutter/material.dart';

import '../../controllers/mutate_workflow_controller.dart';
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
              child: _LeftThumbColumn(controller: mutateController),
            ),
            Expanded(
              flex: 7,
              child: _PianoRollArea(
                songState: songState,
                pianoRollController: pianoRollController,
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
  });

  final MutateWorkflowController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ThumbButton(label: '← 戻る', icon: Icons.arrow_back, onPressed: () {}),
            _ThumbButton(label: '選択', icon: Icons.select_all, onPressed: () {}),
            _ThumbButton(label: '書き込み', icon: Icons.brush, onPressed: () {}),
            _ThumbButton(label: 'スナップ', icon: Icons.grid_on, onPressed: () {}),
            _ThumbButton(label: 'オクターブ ↑', icon: Icons.arrow_upward, onPressed: () {}),
            _ThumbButton(label: 'オクターブ ↓', icon: Icons.arrow_downward, onPressed: () {}),
            const Spacer(),
            MutateButton(controller: controller),
            const SizedBox(height: 12),
            _ThumbButton(label: '鼻歌 (Hum)', icon: Icons.mic, onPressed: () {}),
          ],
        ),
      ),
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
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton.icon(
      icon: Icon(icon),
      onPressed: onPressed,
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: isPrimary
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isPrimary ? Colors.white : Theme.of(context).colorScheme.onSurface,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: button,
    );
  }
}

class _PianoRollArea extends StatelessWidget {
  const _PianoRollArea({
    required this.songState,
    required this.pianoRollController,
  });

  final SongState songState;
  final PianoRollController pianoRollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TrackHeader(pianoRollController: pianoRollController),
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
    required this.pianoRollController,
  });

  final PianoRollController pianoRollController;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ToggleButtons(
              isSelected: const [true, false, false, false],
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Dr'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Ba'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Ch'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Me'),
                ),
              ],
              onPressed: (_) {},
            ),
            AnimatedBuilder(
              animation: pianoRollController,
              builder: (context, _) {
                return Text(
                  'トラック: ${pianoRollController.trackId} | コンテキスト: ${pianoRollController.contextType}',
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
                  color: isPreview
                      ? Colors.orange.withOpacity(0.4)
                      : isSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Note ${note.id} | Pitch ${note.pitch}'),
                    Text('Start ${note.startBeat.toStringAsFixed(2)}'),
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
