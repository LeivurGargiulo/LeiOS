import 'package:flutter_test/flutter_test.dart';
import 'package:leios/domain/models.dart';
import 'package:leios/domain/tasks.dart';

Task task(String id, {DateTime? due, TaskStatus s = TaskStatus.todo, bool u = false, bool i = false, bool lt = false}) => Task(
      id: id, title: id, urgent: u, important: i, status: s, dueDate: due, longTerm: lt,
      createdAt: DateTime.utc(2027), updatedAt: DateTime.utc(2027));

void main() {
  final today = DateTime(2027, 3, 10);

  test('state cycles', () {
    expect(nextTaskStatus(TaskStatus.todo), TaskStatus.doing);
    expect(nextTaskStatus(TaskStatus.doing), TaskStatus.done);
    expect(nextTaskStatus(TaskStatus.done), TaskStatus.todo);
    expect(nextGoalStatus(GoalStatus.pending), GoalStatus.active);
    expect(nextGoalStatus(GoalStatus.active), GoalStatus.completed);
    expect(nextGoalStatus(GoalStatus.completed), GoalStatus.pending);
    expect(nextTaskStatusName('bogus'), 'todo');
    expect(nextGoalStatusName(null), 'pending');
    expect(goalAdvanceLabel(GoalStatus.completed), 'Reopen');
  });

  test('completedAt rules', () {
    final now = DateTime.utc(2027, 3, 10);
    final prev = DateTime.utc(2027, 1, 1);
    expect(completedAtFor(TaskStatus.doing, TaskStatus.done, null, now), now);
    expect(completedAtFor(TaskStatus.done, TaskStatus.done, prev, now), prev);
    expect(completedAtFor(TaskStatus.done, TaskStatus.todo, prev, now), isNull);
    expect(completedAtFor(TaskStatus.todo, TaskStatus.doing, null, now), isNull);
  });

  test('bucketFor boundaries', () {
    expect(bucketFor(DateTime(2027, 3, 9), today), TaskBucket.overdue);
    expect(bucketFor(DateTime(2027, 3, 10), today), TaskBucket.today);
    expect(bucketFor(DateTime(2027, 3, 11), today), TaskBucket.next7);
    expect(bucketFor(DateTime(2027, 3, 17), today), TaskBucket.next7);
    expect(bucketFor(DateTime(2027, 3, 18), today), TaskBucket.later);
    expect(bucketFor(null, today), TaskBucket.noDate);
  });

  test('bucketTasks hides done tasks', () {
    final b = bucketTasks([task('a', due: today), task('b', due: today, s: TaskStatus.done)], today);
    expect(b[TaskBucket.today]!.map((t) => t.id), ['a']);
  });

  test('eisenhower quadrants', () {
    final q = eisenhower([task('a', u: true, i: true), task('b', i: true), task('c', u: true), task('d'), task('e', u: true, i: true, s: TaskStatus.done)]);
    expect(q[(true, true)]!.map((t) => t.id), ['a']);
    expect(q[(false, true)]!.map((t) => t.id), ['b']);
    expect(q[(true, false)]!.map((t) => t.id), ['c']);
    expect(q[(false, false)]!.map((t) => t.id), ['d']);
  });

  test('scope', () {
    final lt = task('x', lt: true);
    expect(inScope(lt, TaskScope.regular), isFalse);
    expect(inScope(lt, TaskScope.longTerm), isTrue);
    expect(inScope(lt, TaskScope.all), isTrue);
  });

  test('dueLabel', () {
    String f(DateTime d) => 'FMT';
    expect(dueLabel(today, today, f), 'Today');
    expect(dueLabel(DateTime(2027, 3, 11), today, f), 'Tomorrow');
    expect(dueLabel(DateTime(2027, 3, 13), today, f), 'Sat');
    expect(dueLabel(DateTime(2027, 3, 9), today, f), 'FMT');
    expect(dueLabel(DateTime(2027, 4, 1), today, f), 'FMT');
  });

  test('greeting', () {
    expect(greetingFor(5), 'Good morning');
    expect(greetingFor(12), 'Good afternoon');
    expect(greetingFor(19), 'Good evening');
  });
}
