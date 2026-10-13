import '../../../l10n/app_localizations.dart';
import '../application/import_plan.dart';

/// The sentence for one issue, in the person's language.
String importIssueText(AppLocalizations l10n, ImportIssue issue) {
  final column = issue.column ?? '';
  final value = issue.value ?? '';
  return switch (issue.kind) {
    ImportIssueKind.notUtf8 => l10n.importIssueNotUtf8,
    ImportIssueKind.unclosedQuote => l10n.importIssueUnclosedQuote(
      issue.line ?? 0,
    ),
    ImportIssueKind.strayQuote => l10n.importIssueStrayQuote(issue.line ?? 0),
    ImportIssueKind.tooManyRows => l10n.importIssueTooManyRows,
    ImportIssueKind.fileTooLarge => l10n.importIssueFileTooLarge,
    ImportIssueKind.notTracklyFile => l10n.importIssueNotTrackly,
    ImportIssueKind.missingColumn => l10n.importIssueMissingColumn(column),
    ImportIssueKind.required => l10n.importIssueRequired(column),
    ImportIssueKind.badAmount => l10n.importIssueBadAmount(value, column),
    ImportIssueKind.badDate => l10n.importIssueBadDate(value, column),
    ImportIssueKind.badChoice => l10n.importIssueBadChoice(value, column),
    ImportIssueKind.badNumber => l10n.importIssueBadNumber(value, column),
    ImportIssueKind.badTime => l10n.importIssueBadTime(value),
    ImportIssueKind.badId => l10n.importIssueBadId(value),
    ImportIssueKind.tooLong => l10n.importIssueTooLong(column),
    ImportIssueKind.tooManyFields => l10n.importIssueTooManyFields,
    ImportIssueKind.duplicateIdInFile => l10n.importIssueDuplicateId(
      issue.otherLine ?? 0,
    ),
    ImportIssueKind.trialNeedsEnd => l10n.importIssueTrialNeedsEnd,
    ImportIssueKind.unknownSubscription => l10n.importIssueUnknownSubscription(
      value,
    ),
    ImportIssueKind.ambiguousSubscription =>
      l10n.importIssueAmbiguousSubscription(value),
    ImportIssueKind.unknownCategory => l10n.importIssueUnknownCategory(value),
    ImportIssueKind.noPaidDate => l10n.importIssueNoPaidDate,
  };
}

/// Where the issue is: "file.csv, line 12", or just the file for a whole-file
/// issue.
String importIssueWhere(AppLocalizations l10n, ImportIssue issue) {
  final line = issue.line;
  return line == null ? issue.file : l10n.importLocation(issue.file, line);
}
