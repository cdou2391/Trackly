import '../../../core/utils/recurrence_utils.dart';
import '../../export/application/csv.dart';
import '../../payments/domain/payment.dart';
import '../../subscriptions/domain/recurring_enums.dart';
import '../../subscriptions/domain/recurring_item.dart';
import 'csv_parser.dart';

/// What was wrong with a row, a file or a value. The screen turns each kind
/// into a sentence in the person's language; nothing here is user-facing text.
enum ImportIssueKind {
  // The whole file.
  notUtf8,
  unclosedQuote,
  strayQuote,
  tooManyRows,
  fileTooLarge,
  notTracklyFile,
  missingColumn,

  // A row (it is skipped).
  required,
  badAmount,
  badDate,
  badChoice,
  badNumber,
  badTime,
  badId,
  tooLong,
  tooManyFields,
  duplicateIdInFile,
  trialNeedsEnd,
  unknownSubscription,
  ambiguousSubscription,

  // A note: the row is still imported.
  unknownCategory,
  noPaidDate,
}

class ImportIssue {
  const ImportIssue(
    this.kind, {
    required this.file,
    this.line,
    this.column,
    this.value,
    this.otherLine,
  });

  final ImportIssueKind kind;
  final String file;

  /// The line in the file (from 1, counting the header), when it is about one.
  final int? line;
  final String? column;

  /// The offending text, shortened.
  final String? value;

  /// For [ImportIssueKind.duplicateIdInFile]: the line that used the id first.
  final int? otherLine;
}

/// One file the person picked, already decoded to text.
class ImportSource {
  const ImportSource({required this.name, required this.text});

  final String name;
  final String text;
}

/// Everything an import would do, worked out before anything is written.
class ImportPlan {
  const ImportPlan({
    required this.newItems,
    required this.newPayments,
    required this.duplicateItems,
    required this.duplicatePayments,
    required this.problems,
    required this.warnings,
    required this.fileProblems,
  });

  final List<RecurringItem> newItems;
  final List<Payment> newPayments;

  /// Rows left out because Trackly already has them.
  final int duplicateItems;
  final int duplicatePayments;

  /// Rows that cannot be imported, each with the reason.
  final List<ImportIssue> problems;

  /// Rows imported with something adjusted.
  final List<ImportIssue> warnings;

  /// Files that could not be read or are not a Trackly file.
  final List<ImportIssue> fileProblems;

  bool get hasAnythingToImport => newItems.isNotEmpty || newPayments.isNotEmpty;
  int get duplicates => duplicateItems + duplicatePayments;

  /// This plan with [extra] file problems added in front (files that were
  /// never read, so [buildImportPlan] never saw them).
  ImportPlan withFileProblems(List<ImportIssue> extra) => ImportPlan(
    newItems: newItems,
    newPayments: newPayments,
    duplicateItems: duplicateItems,
    duplicatePayments: duplicatePayments,
    problems: problems,
    warnings: warnings,
    fileProblems: [...extra, ...fileProblems],
  );
}

const _maxNameLength = 120;
const _maxNotesLength = 2000;
const _maxAmount = 1000000000.0;
const _idPattern = r'^[A-Za-z0-9_-]{1,64}$';

const _subscriptionRequired = [
  'name',
  'amount',
  'currency',
  'frequency',
  'next_due_date',
];
const _paymentRequired = ['due_date', 'status', 'amount'];

/// Works out what importing [sources] would do. Pure, so it is easy to test.
///
/// Two kinds of file are understood, told apart by their columns:
///
/// - **Subscriptions** (`name, amount, currency, frequency, next_due_date`
///   are required; every other column of the export is optional).
/// - **Payments** (`due_date, status, amount` plus `subscription_id` or
///   `subscription`).
///
/// Nothing in Trackly is changed or replaced: rows that Trackly already has
/// (same `id`, or for rows without one the same name, amount, currency,
/// schedule and due date) are counted and skipped, so importing a file twice
/// changes nothing. A row with a problem is skipped and reported; the rest
/// still import. Text written by the export's spreadsheet-formula guard is
/// restored.
ImportPlan buildImportPlan({
  required List<ImportSource> sources,
  required List<RecurringItem> existingItems,
  required List<Payment> existingPayments,
  required Map<String, String> categoryIdsByName,
  required DateTime now,
  required String Function() newId,
}) {
  final problems = <ImportIssue>[];
  final warnings = <ImportIssue>[];
  final fileProblems = <ImportIssue>[];

  final subscriptionFiles = <(ImportSource, CsvTable)>[];
  final paymentFiles = <(ImportSource, CsvTable)>[];

  for (final source in sources) {
    final CsvTable table;
    try {
      table = parseCsv(source.text);
    } on CsvFormatException catch (error) {
      fileProblems.add(
        ImportIssue(
          switch (error.problem) {
            CsvProblem.unclosedQuote => ImportIssueKind.unclosedQuote,
            CsvProblem.strayQuote => ImportIssueKind.strayQuote,
            CsvProblem.tooManyRows => ImportIssueKind.tooManyRows,
          },
          file: source.name,
          line: error.line,
        ),
      );
      continue;
    }

    final headers = table.headers.toSet();
    final isSubscriptions = headers.containsAll(['name', 'amount']);
    final isPayments =
        headers.contains('due_date') &&
        (headers.contains('subscription') ||
            headers.contains('subscription_id'));

    if (isSubscriptions && !isPayments) {
      final missing = _subscriptionRequired.where((c) => !headers.contains(c));
      if (missing.isNotEmpty) {
        for (final column in missing) {
          fileProblems.add(
            ImportIssue(
              ImportIssueKind.missingColumn,
              file: source.name,
              column: column,
            ),
          );
        }
        continue;
      }
      subscriptionFiles.add((source, table));
    } else if (isPayments) {
      final missing = _paymentRequired.where((c) => !headers.contains(c));
      if (missing.isNotEmpty) {
        for (final column in missing) {
          fileProblems.add(
            ImportIssue(
              ImportIssueKind.missingColumn,
              file: source.name,
              column: column,
            ),
          );
        }
        continue;
      }
      paymentFiles.add((source, table));
    } else {
      fileProblems.add(
        ImportIssue(ImportIssueKind.notTracklyFile, file: source.name),
      );
    }
  }

  final itemsById = {for (final item in existingItems) item.id: item};
  final existingKeys = {for (final item in existingItems) _itemKey(item)};
  final importedIds = <String, (String file, int line)>{};
  final newItems = <RecurringItem>[];
  var duplicateItems = 0;

  for (final (source, table) in subscriptionFiles) {
    final reader = _Reader(source.name, table);
    for (final row in table.rows) {
      final result = _readItem(
        reader,
        row,
        categoryIdsByName: categoryIdsByName,
        now: now,
        newId: newId,
      );
      warnings.addAll(result.warnings);
      final item = result.item;
      if (item == null) {
        problems.addAll(result.problems);
        continue;
      }

      final givenId = result.givenId;
      if (givenId != null) {
        final earlier = importedIds[givenId];
        if (earlier != null) {
          problems.add(
            ImportIssue(
              ImportIssueKind.duplicateIdInFile,
              file: source.name,
              line: row.line,
              column: 'id',
              value: givenId,
              otherLine: earlier.$2,
            ),
          );
          continue;
        }
        if (itemsById.containsKey(givenId)) {
          importedIds[givenId] = (source.name, row.line);
          duplicateItems++;
          continue;
        }
      } else if (!existingKeys.add(_itemKey(item))) {
        duplicateItems++;
        continue;
      }

      importedIds[item.id] = (source.name, row.line);
      itemsById[item.id] = item;
      existingKeys.add(_itemKey(item));
      newItems.add(item);
    }
  }

  // Payments can point at an item that was already in Trackly or at one in the
  // subscriptions file just read.
  final itemsByName = <String, List<RecurringItem>>{};
  for (final item in itemsById.values) {
    itemsByName.putIfAbsent(_nameKey(item.name), () => []).add(item);
  }
  final paymentIds = {for (final p in existingPayments) p.id};
  final paymentKeys = {for (final p in existingPayments) _paymentKey(p)};
  final newPayments = <Payment>[];
  var duplicatePayments = 0;

  for (final (source, table) in paymentFiles) {
    final reader = _Reader(source.name, table);
    for (final row in table.rows) {
      final result = _readPayment(
        reader,
        row,
        itemsById: itemsById,
        itemsByName: itemsByName,
        now: now,
        newId: newId,
      );
      warnings.addAll(result.warnings);
      final payment = result.payment;
      if (payment == null) {
        problems.addAll(result.problems);
        continue;
      }

      if (result.givenId != null) {
        if (!paymentIds.add(result.givenId!)) {
          duplicatePayments++;
          continue;
        }
        paymentKeys.add(_paymentKey(payment));
      } else if (!paymentKeys.add(_paymentKey(payment))) {
        duplicatePayments++;
        continue;
      }
      paymentIds.add(payment.id);
      newPayments.add(payment);
    }
  }

  return ImportPlan(
    newItems: newItems,
    newPayments: newPayments,
    duplicateItems: duplicateItems,
    duplicatePayments: duplicatePayments,
    problems: problems,
    warnings: warnings,
    fileProblems: fileProblems,
  );
}

// ---------------------------------------------------------------- reading

class _ItemResult {
  _ItemResult({
    this.item,
    this.givenId,
    this.problems = const [],
    this.warnings = const [],
  });

  final RecurringItem? item;
  final String? givenId;
  final List<ImportIssue> problems;
  final List<ImportIssue> warnings;
}

class _PaymentResult {
  _PaymentResult({
    this.payment,
    this.givenId,
    this.problems = const [],
    this.warnings = const [],
  });

  final Payment? payment;
  final String? givenId;
  final List<ImportIssue> problems;
  final List<ImportIssue> warnings;
}

/// Reads cells of one file by column name.
class _Reader {
  _Reader(this.file, this.table)
    : _index = {
        for (var i = 0; i < table.headers.length; i++)
          if (table.headers[i].isNotEmpty) table.headers[i]: i,
      };

  final String file;
  final CsvTable table;
  final Map<String, int> _index;

  bool has(String column) => _index.containsKey(column);

  /// The trimmed text of [column] in [row], empty if the column or cell is
  /// missing.
  String cell(CsvRow row, String column) {
    final i = _index[column];
    if (i == null || i >= row.fields.length) return '';
    return row.fields[i].trim();
  }

  /// Text typed by the person (not trimmed inside), with the export's
  /// formula guard removed.
  String text(CsvRow row, String column) {
    final i = _index[column];
    if (i == null || i >= row.fields.length) return '';
    return csvTextRestore(row.fields[i].trim());
  }

  ImportIssue issue(
    ImportIssueKind kind,
    CsvRow row, {
    String? column,
    String? value,
  }) => ImportIssue(
    kind,
    file: file,
    line: row.line,
    column: column,
    value: value == null ? null : _shorten(value),
  );
}

String _shorten(String value) =>
    value.length <= 40 ? value : '${value.substring(0, 40)}...';

_ItemResult _readItem(
  _Reader r,
  CsvRow row, {
  required Map<String, String> categoryIdsByName,
  required DateTime now,
  required String Function() newId,
}) {
  final problems = <ImportIssue>[];
  final warnings = <ImportIssue>[];

  // More cells than columns, with something in the extra ones, usually means
  // an unquoted comma in a name.
  if (row.fields.length > r.table.headers.length &&
      row.fields.skip(r.table.headers.length).any((f) => f.trim().isNotEmpty)) {
    problems.add(r.issue(ImportIssueKind.tooManyFields, row));
  }

  final name = r.text(row, 'name');
  if (name.isEmpty) {
    problems.add(r.issue(ImportIssueKind.required, row, column: 'name'));
  } else if (name.length > _maxNameLength) {
    problems.add(r.issue(ImportIssueKind.tooLong, row, column: 'name'));
  }

  final amount = _amount(r, row, 'amount', problems, required: true);
  final currency = _currency(r, row, problems);
  final frequency = _frequency(r, row, problems);
  final nextDue = _date(r, row, 'next_due_date', problems, required: true);

  final type = _choice(
    r,
    row,
    'type',
    {
      'subscription': RecurringItemType.subscription,
      'bill': RecurringItemType.bill,
    },
    RecurringItemType.subscription,
    problems,
  );
  final status = _choice(
    r,
    row,
    'status',
    {
      'active': ItemStatus.active,
      'paused': ItemStatus.paused,
      'cancelled': ItemStatus.cancelled,
      'canceled': ItemStatus.cancelled,
    },
    ItemStatus.active,
    problems,
  );
  final every = _integer(r, row, 'every', 1, 1, 3650, problems);
  final startDate = _date(r, row, 'start_date', problems);
  final isTrial = _yesNo(r, row, 'free_trial', false, problems);
  final trialEnd = _date(r, row, 'trial_end_date', problems);
  if (isTrial == true &&
      trialEnd == null &&
      r.cell(row, 'trial_end_date').isEmpty) {
    problems.add(
      r.issue(ImportIssueKind.trialNeedsEnd, row, column: 'trial_end_date'),
    );
  }
  final remindersOn = _yesNo(r, row, 'reminders', true, problems);
  final reminderDays = _integer(
    r,
    row,
    'reminder_days_before',
    3,
    0,
    30,
    problems,
  );
  final reminderMinute = _time(r, row, problems);
  final addedOn = _date(r, row, 'added_on', problems);

  final notes = r.text(row, 'notes');
  if (notes.length > _maxNotesLength) {
    problems.add(r.issue(ImportIssueKind.tooLong, row, column: 'notes'));
  }

  String? categoryId;
  final categoryName = r.text(row, 'category');
  if (categoryName.isNotEmpty) {
    categoryId = categoryIdsByName[categoryName.toLowerCase()];
    if (categoryId == null) {
      warnings.add(
        r.issue(
          ImportIssueKind.unknownCategory,
          row,
          column: 'category',
          value: categoryName,
        ),
      );
    }
  }

  final rawId = r.cell(row, 'id');
  String? givenId;
  if (rawId.isNotEmpty) {
    if (RegExp(_idPattern).hasMatch(rawId)) {
      givenId = rawId;
    } else {
      problems.add(
        r.issue(ImportIssueKind.badId, row, column: 'id', value: rawId),
      );
    }
  }

  if (problems.isNotEmpty ||
      amount == null ||
      currency == null ||
      frequency == null ||
      nextDue == null ||
      isTrial == null ||
      remindersOn == null) {
    return _ItemResult(problems: problems, warnings: const []);
  }

  final item = RecurringItem(
    id: givenId ?? newId(),
    name: name,
    type: type!,
    amount: amount,
    currencyCode: currency,
    frequency: frequency,
    interval: every!,
    startDate: startDate ?? nextDue,
    nextDueDate: nextDue,
    status: status!,
    isTrial: isTrial,
    trialEndDate: isTrial ? trialEnd : null,
    remindersEnabled: remindersOn,
    reminderDaysBefore: reminderDays!,
    reminderMinuteOfDay: reminderMinute!,
    categoryId: categoryId,
    notes: notes.isEmpty ? null : notes,
    createdAt: addedOn ?? dateOnly(now),
    updatedAt: now,
  );
  return _ItemResult(item: item, givenId: givenId, warnings: warnings);
}

_PaymentResult _readPayment(
  _Reader r,
  CsvRow row, {
  required Map<String, RecurringItem> itemsById,
  required Map<String, List<RecurringItem>> itemsByName,
  required DateTime now,
  required String Function() newId,
}) {
  final problems = <ImportIssue>[];
  final warnings = <ImportIssue>[];

  if (row.fields.length > r.table.headers.length &&
      row.fields.skip(r.table.headers.length).any((f) => f.trim().isNotEmpty)) {
    problems.add(r.issue(ImportIssueKind.tooManyFields, row));
  }

  // Which subscription: by id when the row has one, otherwise by name.
  RecurringItem? item;
  final subscriptionId = r.cell(row, 'subscription_id');
  final subscriptionName = r.text(row, 'subscription');
  if (subscriptionId.isNotEmpty) {
    item = itemsById[subscriptionId];
    if (item == null) {
      problems.add(
        r.issue(
          ImportIssueKind.unknownSubscription,
          row,
          column: 'subscription_id',
          value: subscriptionId,
        ),
      );
    }
  } else if (subscriptionName.isEmpty) {
    problems.add(
      r.issue(ImportIssueKind.required, row, column: 'subscription'),
    );
  } else {
    final matches = itemsByName[_nameKey(subscriptionName)] ?? const [];
    if (matches.isEmpty) {
      problems.add(
        r.issue(
          ImportIssueKind.unknownSubscription,
          row,
          column: 'subscription',
          value: subscriptionName,
        ),
      );
    } else if (matches.length > 1) {
      problems.add(
        r.issue(
          ImportIssueKind.ambiguousSubscription,
          row,
          column: 'subscription',
          value: subscriptionName,
        ),
      );
    } else {
      item = matches.single;
    }
  }

  final due = _date(r, row, 'due_date', problems, required: true);
  var paid = _date(r, row, 'paid_date', problems);
  final status = _choice(
    r,
    row,
    'status',
    {
      'paid': PaymentStatus.paid,
      'skipped': PaymentStatus.skipped,
      'upcoming': PaymentStatus.upcoming,
    },
    null,
    problems,
    required: true,
  );
  final amount = _amount(r, row, 'amount', problems, required: true);

  String? currency;
  if (r.cell(row, 'currency').isEmpty) {
    currency = item?.currencyCode;
  } else {
    currency = _currency(r, row, problems);
  }

  final rawId = r.cell(row, 'id');
  String? givenId;
  if (rawId.isNotEmpty) {
    if (RegExp(_idPattern).hasMatch(rawId)) {
      givenId = rawId;
    } else {
      problems.add(
        r.issue(ImportIssueKind.badId, row, column: 'id', value: rawId),
      );
    }
  }

  if (problems.isNotEmpty ||
      item == null ||
      due == null ||
      status == null ||
      amount == null ||
      currency == null) {
    return _PaymentResult(problems: problems);
  }

  if (status == PaymentStatus.paid && paid == null) {
    warnings.add(r.issue(ImportIssueKind.noPaidDate, row, column: 'paid_date'));
    paid = due;
  }

  final payment = Payment(
    id: givenId ?? newId(),
    recurringItemId: item.id,
    amount: amount,
    currencyCode: currency,
    dueDate: due,
    paidDate: status == PaymentStatus.paid ? paid : null,
    status: status,
    createdAt: now,
  );
  return _PaymentResult(payment: payment, givenId: givenId, warnings: warnings);
}

// --------------------------------------------------------- value parsing

double? _amount(
  _Reader r,
  CsvRow row,
  String column,
  List<ImportIssue> problems, {
  bool required = false,
}) {
  final raw = r.cell(row, column);
  if (raw.isEmpty) {
    if (required) {
      problems.add(r.issue(ImportIssueKind.required, row, column: column));
    }
    return null;
  }
  // A comma is the decimal separator only when it is not also the column
  // separator (the usual "15,49" in a semicolon file).
  final decimalComma = r.table.delimiter != ',';
  final pattern = decimalComma ? r'^\d+([.,]\d+)?$' : r'^\d+(\.\d+)?$';
  final value = RegExp(pattern).hasMatch(raw)
      ? double.tryParse(raw.replaceFirst(',', '.'))
      : null;
  if (value == null || !value.isFinite || value > _maxAmount) {
    problems.add(
      r.issue(ImportIssueKind.badAmount, row, column: column, value: raw),
    );
    return null;
  }
  return value;
}

String? _currency(_Reader r, CsvRow row, List<ImportIssue> problems) {
  final raw = r.cell(row, 'currency');
  if (raw.isEmpty) {
    problems.add(r.issue(ImportIssueKind.required, row, column: 'currency'));
    return null;
  }
  if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(raw)) {
    problems.add(
      r.issue(ImportIssueKind.badChoice, row, column: 'currency', value: raw),
    );
    return null;
  }
  return raw.toUpperCase();
}

BillingFrequency? _frequency(
  _Reader r,
  CsvRow row,
  List<ImportIssue> problems,
) {
  final raw = r.cell(row, 'frequency');
  if (raw.isEmpty) {
    problems.add(r.issue(ImportIssueKind.required, row, column: 'frequency'));
    return null;
  }
  final value = switch (raw.toLowerCase().replaceAll('-', '_')) {
    'weekly' => BillingFrequency.weekly,
    'monthly' => BillingFrequency.monthly,
    'quarterly' => BillingFrequency.quarterly,
    'semi_annual' || 'semiannual' => BillingFrequency.semiAnnual,
    'yearly' || 'annual' => BillingFrequency.yearly,
    'custom_days' || 'custom' => BillingFrequency.custom,
    _ => null,
  };
  if (value == null) {
    problems.add(
      r.issue(ImportIssueKind.badChoice, row, column: 'frequency', value: raw),
    );
  }
  return value;
}

/// A value from a fixed list. A blank cell gives [fallback] (or a "required"
/// problem when [required]); anything else not in the list is a problem.
T? _choice<T>(
  _Reader r,
  CsvRow row,
  String column,
  Map<String, T> options,
  T? fallback,
  List<ImportIssue> problems, {
  bool required = false,
}) {
  final raw = r.cell(row, column);
  if (raw.isEmpty) {
    if (required) {
      problems.add(r.issue(ImportIssueKind.required, row, column: column));
    }
    return fallback;
  }
  final value = options[raw.toLowerCase()];
  if (value == null) {
    problems.add(
      r.issue(ImportIssueKind.badChoice, row, column: column, value: raw),
    );
  }
  return value;
}

/// Yes or no (also true/false, 1/0, y/n). Null only when the cell is
/// something else, which is also recorded as a problem.
bool? _yesNo(
  _Reader r,
  CsvRow row,
  String column,
  bool fallback,
  List<ImportIssue> problems,
) {
  final raw = r.cell(row, column);
  if (raw.isEmpty) return fallback;
  switch (raw.toLowerCase()) {
    case 'yes' || 'true' || '1' || 'y':
      return true;
    case 'no' || 'false' || '0' || 'n':
      return false;
  }
  problems.add(
    r.issue(ImportIssueKind.badChoice, row, column: column, value: raw),
  );
  return null;
}

int? _integer(
  _Reader r,
  CsvRow row,
  String column,
  int fallback,
  int min,
  int max,
  List<ImportIssue> problems,
) {
  final raw = r.cell(row, column);
  if (raw.isEmpty) return fallback;
  final value = RegExp(r'^\d{1,6}$').hasMatch(raw) ? int.parse(raw) : null;
  if (value == null || value < min || value > max) {
    problems.add(
      r.issue(ImportIssueKind.badNumber, row, column: column, value: raw),
    );
    return null;
  }
  return value;
}

int? _time(_Reader r, CsvRow row, List<ImportIssue> problems) {
  final raw = r.cell(row, 'reminder_time');
  if (raw.isEmpty) return defaultReminderMinuteOfDay;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw);
  final hour = match == null ? null : int.parse(match.group(1)!);
  final minute = match == null ? null : int.parse(match.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    problems.add(
      r.issue(
        ImportIssueKind.badTime,
        row,
        column: 'reminder_time',
        value: raw,
      ),
    );
    return null;
  }
  return hour * 60 + minute;
}

/// A date written `YYYY-MM-DD` that really exists. Blank is null (and a
/// "required" problem when [required]).
DateTime? _date(
  _Reader r,
  CsvRow row,
  String column,
  List<ImportIssue> problems, {
  bool required = false,
}) {
  final raw = r.cell(row, column);
  if (raw.isEmpty) {
    if (required) {
      problems.add(r.issue(ImportIssueKind.required, row, column: column));
    }
    return null;
  }
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (match != null) {
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (year >= 1900 &&
        year <= 2200 &&
        date.year == year &&
        date.month == month &&
        date.day == day) {
      return date;
    }
  }
  problems.add(
    r.issue(ImportIssueKind.badDate, row, column: column, value: raw),
  );
  return null;
}

// ------------------------------------------------------------ comparing

String _nameKey(String name) => name.trim().toLowerCase();

/// What makes two rows "the same subscription" when they have no id.
String _itemKey(RecurringItem item) => [
  _nameKey(item.name),
  item.amount.toStringAsFixed(2),
  item.currencyCode,
  item.frequency.name,
  item.interval,
  dateOnly(item.nextDueDate).toIso8601String(),
].join('|');

String _paymentKey(Payment payment) => [
  payment.recurringItemId,
  dateOnly(payment.dueDate).toIso8601String(),
  payment.status.name,
  payment.amount.toStringAsFixed(2),
  payment.currencyCode,
].join('|');
