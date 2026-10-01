import '../core/validation/validation.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import 'crud_repository.dart';

class EventsRepo extends CrudRepository {
  EventsRepo(super.db, {required super.userId, super.clock});

  Stream<List<Event>> watchAll() => watchRows('SELECT * FROM events ORDER BY date', Event.fromRow);

  Future<Event?> get(String id) async {
    final r = await db.getOptional('SELECT * FROM events WHERE id = ?', [id]);
    return r == null ? null : Event.fromRow(r);
  }

  Map<String, Object?> _values({
    required String title,
    required String description,
    required DateTime date,
    DateTime? endDate,
    int? startMinutes,
    int? endMinutes,
    int? weekdays,
    DateTime? until,
  }) {
    final t = requiredText(title, 'Title');
    validateEventTimes(
      date: date,
      endDate: endDate,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      weekdays: weekdays,
      until: until,
    );
    return {
      'title': t,
      'description': description,
      'date': isoDate(date),
      'end_date': endDate == null ? null : isoDate(endDate),
      'start_minutes': startMinutes,
      'end_minutes': endMinutes,
      'weekdays': weekdays,
      'until': until == null ? null : isoDate(until),
    };
  }

  Future<String> create({
    required String title,
    String description = '',
    required DateTime date,
    DateTime? endDate,
    int? startMinutes,
    int? endMinutes,
    int? weekdays,
    DateTime? until,
    String? id,
  }) async {
    final values = _values(
      title: title,
      description: description,
      date: date,
      endDate: endDate,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      weekdays: weekdays,
      until: until,
    );
    final rowId = id ?? newRowId();
    await db.writeTransaction((tx) => insertRow(tx, 'events', {'id': rowId, ...values, 'created_at': nowIso}));
    return rowId;
  }

  /// Full replace of the editable fields (editing a recurring event edits the series).
  Future<void> update(
    String id, {
    required String title,
    String description = '',
    required DateTime date,
    DateTime? endDate,
    int? startMinutes,
    int? endMinutes,
    int? weekdays,
    DateTime? until,
  }) async {
    final values = _values(
      title: title,
      description: description,
      date: date,
      endDate: endDate,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      weekdays: weekdays,
      until: until,
    );
    await db.writeTransaction((tx) => updateColumns(tx, 'events', id, values));
  }

  Future<void> delete(String id) => db.execute('DELETE FROM events WHERE id = ?', [id]);

  Future<void> restore(Event e) => create(
        id: e.id,
        title: e.title,
        description: e.description,
        date: e.date,
        endDate: e.endDate,
        startMinutes: e.startMinutes,
        endMinutes: e.endMinutes,
        weekdays: e.weekdays,
        until: e.until,
      );
}
