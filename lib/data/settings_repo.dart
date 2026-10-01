import '../core/ids/ids.dart';
import '../core/validation/validation.dart';
import '../domain/models.dart';
import 'crud_repository.dart';

class SettingsRepo extends CrudRepository {
  SettingsRepo(super.db, {required super.userId, super.clock});

  Stream<AppSettings> watch() => db
      .watch('SELECT * FROM settings LIMIT 1')
      .map((rs) => rs.isEmpty ? const AppSettings() : AppSettings.fromRow(rs.first));

  Future<void> save({String? dateFormat, String? displayName}) async {
    if (dateFormat != null) validateDateFormat(dateFormat);
    final id = settingsId(userId);
    await db.writeTransaction((tx) async {
      final existing = await tx.getOptional('SELECT id FROM settings WHERE id = ?', [id]);
      if (existing == null) {
        await insertRow(tx, 'settings', {
          'id': id,
          'date_format': dateFormat ?? const AppSettings().dateFormat,
          'display_name': (displayName ?? '').trim(),
        });
      } else {
        await updateColumns(tx, 'settings', id, {
          'date_format': ?dateFormat,
          if (displayName != null) 'display_name': displayName.trim(),
        });
      }
    });
  }
}
