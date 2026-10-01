import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Fixed namespace for deterministic (v5) ids of natural-key rows.
const appNamespace = '6f1c2b7e-3a5d-4c8e-9b1a-4d2e7f0a9c11';

String newId() => _uuid.v4();

String _v5(String name) => _uuid.v5(appNamespace, name);

/// `feelings` → key `date`.
String feelingId(String userId, String isoDate) => _v5('$userId|feeling|$isoDate');

/// `habit_completions` → key `habit_id|date`.
String habitCompletionId(String userId, String habitId, String isoDate) =>
    _v5('$userId|habit_completion|$habitId|$isoDate');

/// `settings` → `id = user_id`.
String settingsId(String userId) => userId;
