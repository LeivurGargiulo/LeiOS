import '../core/validation/validation.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import 'crud_repository.dart';

class FinanceRepo extends CrudRepository {
  FinanceRepo(super.db, {required super.userId, super.clock});

  Stream<List<Tx>> watchTransactions() =>
      watchRows('SELECT * FROM transactions ORDER BY date DESC, created_at DESC', Tx.fromRow);

  Stream<List<SavingsFund>> watchFunds() =>
      watchRows('SELECT * FROM savings_funds ORDER BY created_at', SavingsFund.fromRow);

  Future<String?> _checkedFund(dynamic tx, TxType type, String? fundId) async {
    final id = fundIdFor(type, fundId);
    if (id == null) return null;
    final row = await tx.getOptional('SELECT id FROM savings_funds WHERE id = ?', [id]);
    if (row == null) throw ValidationException('That savings fund no longer exists.');
    return id;
  }

  Future<String> createTransaction({
    required int amount,
    required TxType type,
    String category = '',
    String note = '',
    required DateTime date,
    String? savingsFundId,
    String? id,
  }) async {
    final a = atLeast(amount, 1, 'Amount');
    final rowId = id ?? newRowId();
    await db.writeTransaction((tx) async {
      final fund = await _checkedFund(tx, type, savingsFundId);
      await insertRow(tx, 'transactions', {
        'id': rowId,
        'amount': a,
        'type': txTypeToDb(type),
        'category': category.trim(),
        'note': note,
        'date': isoDate(date),
        'savings_fund_id': fund,
        'created_at': nowIso,
      });
    });
    return rowId;
  }

  Future<void> updateTransaction(
    String id, {
    required int amount,
    required TxType type,
    String category = '',
    String note = '',
    required DateTime date,
    String? savingsFundId,
  }) async {
    final a = atLeast(amount, 1, 'Amount');
    await db.writeTransaction((tx) async {
      final fund = await _checkedFund(tx, type, savingsFundId);
      await updateColumns(tx, 'transactions', id, {
        'amount': a,
        'type': txTypeToDb(type),
        'category': category.trim(),
        'note': note,
        'date': isoDate(date),
        'savings_fund_id': fund,
      });
    });
  }

  Future<void> deleteTransaction(String id) => db.execute('DELETE FROM transactions WHERE id = ?', [id]);

  Future<void> restoreTransaction(Tx t) => createTransaction(
        id: t.id,
        amount: t.amount,
        type: t.type,
        category: t.category,
        note: t.note,
        date: t.date,
        savingsFundId: t.savingsFundId,
      );

  Future<String> createFund({required String name, required int targetAmount}) async {
    final n = requiredText(name, 'Name');
    final t = atLeast(targetAmount, 1, 'Target amount');
    final id = newRowId();
    await db.writeTransaction((tx) => insertRow(tx, 'savings_funds', {
          'id': id,
          'name': n,
          'target_amount': t,
          'created_at': nowIso,
        }));
    return id;
  }

  Future<void> updateFund(String id, {String? name, int? targetAmount}) async {
    await db.writeTransaction((tx) => updateColumns(tx, 'savings_funds', id, {
          if (name != null) 'name': requiredText(name, 'Name'),
          if (targetAmount != null) 'target_amount': atLeast(targetAmount, 1, 'Target amount'),
        }));
  }

  /// SET NULL on linked transactions (they are kept), then delete the fund.
  Future<void> deleteFund(String id) => db.writeTransaction((tx) async {
        await tx.execute('UPDATE transactions SET savings_fund_id = NULL WHERE savings_fund_id = ?', [id]);
        await tx.execute('DELETE FROM savings_funds WHERE id = ?', [id]);
      });
}
