import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/error/error_reporter.dart';
import '../../home/application/home_providers.dart';
import '../../subscriptions/application/catalog_backfill.dart';
import 'import_plan.dart';

/// The largest file read for an import. A real export is a few kilobytes;
/// anything near this size is not one.
const maxImportFileBytes = 5 * 1024 * 1024;

/// A file the person picked. [bytes] is empty when it was [tooLarge] (it is
/// never read).
class PickedCsv {
  const PickedCsv({
    required this.name,
    required this.bytes,
    this.tooLarge = false,
  });

  final String name;
  final Uint8List bytes;
  final bool tooLarge;
}

/// Lets the person choose files. A seam, so tests do not need the plugin.
abstract class CsvPicker {
  /// The chosen files, or an empty list if they cancelled.
  Future<List<PickedCsv>> pick();
}

/// The system file chooser (Android's document picker): no storage permission
/// is needed, and Trackly only sees the files the person picks.
class FileSelectorCsvPicker implements CsvPicker {
  const FileSelectorCsvPicker();

  @override
  Future<List<PickedCsv>> pick() async {
    // No type filter: phones label CSV files inconsistently (text/csv,
    // text/plain, octet-stream), and the content is checked anyway.
    final files = await openFiles();
    final picked = <PickedCsv>[];
    for (final file in files) {
      if (await file.length() > maxImportFileBytes) {
        picked.add(
          PickedCsv(name: file.name, bytes: Uint8List(0), tooLarge: true),
        );
      } else {
        picked.add(PickedCsv(name: file.name, bytes: await file.readAsBytes()));
      }
    }
    return picked;
  }
}

final csvPickerProvider = Provider<CsvPicker>(
  (ref) => const FileSelectorCsvPicker(),
);

/// Thrown by [decodeCsvBytes] for bytes that are not readable text.
class CsvDecodeException implements Exception {
  const CsvDecodeException();
}

/// Turns file bytes into text: UTF-8 (the usual and what the export writes),
/// or UTF-16 when the file starts with that byte order mark (Excel's "Unicode
/// text"). Anything else, such as a Windows-1252 file with accents, is
/// refused rather than guessed at, because guessing garbles names.
String decodeCsvBytes(List<int> bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    return _utf16(bytes, littleEndian: true);
  }
  if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
    return _utf16(bytes, littleEndian: false);
  }
  try {
    return utf8.decode(bytes);
  } on FormatException {
    throw const CsvDecodeException();
  }
}

String _utf16(List<int> bytes, {required bool littleEndian}) {
  final units = <int>[];
  for (var i = 2; i + 1 < bytes.length; i += 2) {
    units.add(
      littleEndian
          ? bytes[i] | (bytes[i + 1] << 8)
          : (bytes[i] << 8) | bytes[i + 1],
    );
  }
  return String.fromCharCodes(units);
}

/// What an import changed.
class ImportResult {
  const ImportResult({required this.items, required this.payments});

  final int items;
  final int payments;
}

/// Reads files the person picks, shows what they would change, and applies it
/// only when told to.
class DataImporter {
  DataImporter(this._ref);

  final Ref _ref;

  /// Asks the person for files and works out what importing them would do.
  /// Returns null when they picked nothing. Nothing is written.
  Future<ImportPlan?> prepare() async {
    final files = await _ref.read(csvPickerProvider).pick();
    if (files.isEmpty) return null;
    return planFor(files);
  }

  /// The plan for files already picked. Separate from [prepare] so it can be
  /// tested without a file chooser.
  Future<ImportPlan> planFor(List<PickedCsv> files) async {
    final fileProblems = <ImportIssue>[];
    final sources = <ImportSource>[];
    for (final file in files) {
      if (file.tooLarge) {
        fileProblems.add(
          ImportIssue(ImportIssueKind.fileTooLarge, file: file.name),
        );
        continue;
      }
      try {
        sources.add(
          ImportSource(name: file.name, text: decodeCsvBytes(file.bytes)),
        );
      } on CsvDecodeException {
        fileProblems.add(ImportIssue(ImportIssueKind.notUtf8, file: file.name));
      }
    }

    final db = _ref.read(appDatabaseProvider);
    final categories = await db.categoriesDao.getAll();
    final plan = buildImportPlan(
      sources: sources,
      existingItems: await db.recurringItemsDao.getAll(),
      existingPayments: await db.paymentsDao.getAll(),
      categoryIdsByName: {
        for (final c in categories) c.name.toLowerCase(): c.id,
      },
      now: _ref.read(nowProvider)(),
      newId: () => const Uuid().v4(),
    );
    return plan.withFileProblems(fileProblems);
  }

  /// Writes the plan: every item and payment, or none of them (one database
  /// transaction). Reminders follow on their own, because they watch the
  /// items.
  Future<ImportResult> apply(ImportPlan plan) async {
    final db = _ref.read(appDatabaseProvider);
    final errors = _ref.read(errorReporterProvider);
    try {
      errors.addBreadcrumb('import_started', category: 'ui');
      await db.transaction(() async {
        for (final item in plan.newItems) {
          await db.recurringItemsDao.insertItem(item);
        }
        for (final payment in plan.newPayments) {
          await db.paymentsDao.insertPayment(payment);
        }
      });
    } catch (error, stackTrace) {
      await errors.captureException(error, stackTrace);
      rethrow;
    }

    // Logos are cosmetic: a failure here must not undo or fail the import.
    try {
      await backfillCatalogLogos(db);
    } catch (error, stackTrace) {
      await errors.captureException(error, stackTrace);
    }
    return ImportResult(
      items: plan.newItems.length,
      payments: plan.newPayments.length,
    );
  }
}

final dataImporterProvider = Provider<DataImporter>(DataImporter.new);
