import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'data_export.dart';

/// Shares the export through the Android share sheet (share_plus).
///
/// The files are built in memory and handed over by share_plus, which keeps
/// the temporary copy it needs for the receiving app; Trackly writes no file
/// of its own.
class SharePlusDataSharer implements DataSharer {
  const SharePlusDataSharer();

  @override
  Future<void> shareFiles(List<ExportFile> files, {required String title}) {
    return SharePlus.instance.share(
      ShareParams(
        title: title,
        files: [
          for (final file in files)
            XFile.fromData(
              Uint8List.fromList(file.bytes),
              mimeType: 'text/csv',
              name: file.name,
            ),
        ],
        fileNameOverrides: [for (final file in files) file.name],
      ),
    );
  }
}
