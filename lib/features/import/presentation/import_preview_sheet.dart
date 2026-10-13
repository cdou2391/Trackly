import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../l10n/l10n.dart';
import '../application/import_plan.dart';
import 'import_issue_text.dart';

/// How many problems and notes are listed before "…and N more".
const _listed = 6;

/// Shows what importing would do and asks for a go-ahead. Resolves to true
/// only when the person confirms; nothing has been changed before that.
Future<bool?> showImportPreview(BuildContext context, ImportPlan plan) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _ImportPreview(plan: plan),
  );
}

class _ImportPreview extends StatelessWidget {
  const _ImportPreview({required this.plan});

  final ImportPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final danger = context.tokens.danger.fg;
    final canImport = plan.hasAnythingToImport;
    final skipping = plan.problems.isNotEmpty;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                TracklySpacing.lg,
                0,
                TracklySpacing.lg,
                TracklySpacing.base,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.importReviewTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: TracklySpacing.md),
                if (!canImport && plan.fileProblems.isEmpty)
                  Text(l10n.importNothing, style: theme.textTheme.bodyLarge),
                if (plan.newItems.isNotEmpty)
                  _Line(
                    icon: Icons.add_circle_outline_rounded,
                    text: l10n.importNewSubscriptions(plan.newItems.length),
                  ),
                if (plan.newPayments.isNotEmpty)
                  _Line(
                    icon: Icons.add_circle_outline_rounded,
                    text: l10n.importNewPayments(plan.newPayments.length),
                  ),
                if (plan.duplicates > 0)
                  _Line(
                    icon: Icons.content_copy_rounded,
                    text: l10n.importDuplicates(plan.duplicates),
                  ),
                if (plan.problems.isNotEmpty)
                  _Line(
                    icon: Icons.error_outline_rounded,
                    text: l10n.importProblemRows(_problemRows(plan)),
                    color: danger,
                  ),
                if (plan.fileProblems.isNotEmpty)
                  _IssueList(
                    title: l10n.importFilesHeader,
                    issues: plan.fileProblems,
                    color: danger,
                  ),
                if (plan.problems.isNotEmpty)
                  _IssueList(
                    title: l10n.importProblemsHeader,
                    issues: plan.problems,
                    color: danger,
                  ),
                if (plan.warnings.isNotEmpty)
                  _IssueList(
                    title: l10n.importNotesHeader,
                    issues: plan.warnings,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TracklySpacing.lg,
              TracklySpacing.sm,
              TracklySpacing.lg,
              TracklySpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canImport)
                  FilledButton(
                    key: const Key('import-confirm'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      skipping
                          ? l10n.importConfirmSkipping
                          : l10n.importConfirm,
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (canImport) const SizedBox(height: TracklySpacing.sm),
                OutlinedButton(
                  key: const Key('import-cancel'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(canImport ? l10n.importCancel : l10n.importClose),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A row with two problems is still one skipped row.
  static int _problemRows(ImportPlan plan) =>
      {for (final issue in plan.problems) (issue.file, issue.line)}.length;
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: TracklySpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 20, color: tint)),
          const SizedBox(width: TracklySpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(color: tint),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueList extends StatelessWidget {
  const _IssueList({required this.title, required this.issues, this.color});

  final String title;
  final List<ImportIssue> issues;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final shown = issues.take(_listed).toList();
    final more = issues.length - shown.length;

    return Padding(
      padding: const EdgeInsets.only(top: TracklySpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: TracklySpacing.xs),
          for (final issue in shown) _IssueRow(l10n: l10n, issue: issue),
          if (more > 0)
            Text(l10n.importMore(more), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.l10n, required this.issue});

  final AppLocalizations l10n;
  final ImportIssue issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: TracklySpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            importIssueWhere(l10n, issue),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(importIssueText(l10n, issue), style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
