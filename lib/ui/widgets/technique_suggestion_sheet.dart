import 'package:flutter/material.dart';

import '../../controllers/mutate_workflow_controller.dart';
import '../../models/technique.dart';

class TechniqueSuggestionSheet extends StatefulWidget {
  const TechniqueSuggestionSheet({
    super.key,
    required this.controller,
    required this.techniques,
  });

  final MutateWorkflowController controller;
  final List<Technique> techniques;

  @override
  State<TechniqueSuggestionSheet> createState() =>
      _TechniqueSuggestionSheetState();
}

class _TechniqueSuggestionSheetState extends State<TechniqueSuggestionSheet> {
  Technique? _selectedTechnique;
  bool _confirmMode = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '介入提案',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (_confirmMode) ...[
                _buildPreviewCard(context),
                const SizedBox(height: 20),
                _buildConfirmButtons(context),
              ] else ...[
                _buildTechniqueList(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechniqueList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final technique in widget.techniques) ...[
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    await _onTechniqueSelected(context, technique);
                  },
            style: ElevatedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(technique.name),
                const SizedBox(height: 4),
                Text(
                  technique.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedTechnique?.name ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_selectedTechnique?.description ?? ''),
            if (widget.controller.isBusy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.controller.isBusy
                ? null
                : () {
                    widget.controller.cancelPreview();
                    setState(() {
                      _confirmMode = false;
                      _selectedTechnique = null;
                    });
                  },
            child: const Text('キャンセル'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: widget.controller.isBusy
                ? null
                : () {
                    widget.controller.applyPreview();
                    Navigator.of(context).pop();
                  },
            child: const Text('この変更を適用'),
          ),
        ),
      ],
    );
  }

  Future<void> _onTechniqueSelected(
    BuildContext context,
    Technique technique,
  ) async {
    setState(() {
      _isLoading = true;
    });
    await widget.controller.previewTechnique(technique);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _selectedTechnique = technique;
      _confirmMode = true;
    });
  }
}
