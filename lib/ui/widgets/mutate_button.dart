import 'package:flutter/material.dart';

import '../../controllers/mutate_workflow_controller.dart';
import 'technique_suggestion_sheet.dart';

/// L字型操作系の左親指エリアに常設される `[ MUTATE ]` ボタン。
class MutateButton extends StatelessWidget {
  const MutateButton({
    super.key,
    required this.controller,
  });

  final MutateWorkflowController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final enabled = controller.isMutateEnabled;
        return SizedBox(
          height: 72,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: enabled ? () => _handlePressed(context) : null,
            child: const Text('[ MUTATE ]'),
          ),
        );
      },
    );
  }

  Future<void> _handlePressed(BuildContext context) async {
    final techniques = await controller.fetchTechniquesForSelection();
    if (context.mounted) {
      if (techniques.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('適用可能な技法が見つかりません。')),
        );
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return TechniqueSuggestionSheet(
            controller: controller,
            techniques: techniques,
          );
        },
      );
      controller.cancelPreview();
    }
  }
}
