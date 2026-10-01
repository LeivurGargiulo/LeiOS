import 'models.dart';

class MonthlySummary {
  const MonthlySummary({
    required this.income,
    required this.expenses,
    required this.saved,
    required this.byCategory,
  });
  final int income;
  final int expenses;
  final int saved;
  final List<({String category, int amount})> byCategory;
  int get balance => income - expenses - saved;
}

const uncategorized = 'Uncategorized';

MonthlySummary monthlySummary(Iterable<Tx> txs, int year, int month) {
  var income = 0, expenses = 0, saved = 0;
  final cats = <String, int>{};
  for (final t in txs.where((t) => t.date.year == year && t.date.month == month)) {
    switch (t.type) {
      case TxType.income:
        income += t.amount;
      case TxType.expense:
        expenses += t.amount;
        final c = t.category.trim().isEmpty ? uncategorized : t.category;
        cats[c] = (cats[c] ?? 0) + t.amount;
      case TxType.savingsContribution:
        saved += t.amount;
    }
  }
  final list = [for (final e in cats.entries) (category: e.key, amount: e.value)];
  list.sort((a, b) {
    final c = b.amount.compareTo(a.amount);
    return c != 0 ? c : a.category.compareTo(b.category);
  });
  return MonthlySummary(income: income, expenses: expenses, saved: saved, byCategory: list);
}

/// Percent 0..100 of [target] reached by [current].
double fundProgress(int current, int target) =>
    target <= 0 ? 0 : (current / target * 100).clamp(0, 100).toDouble();

int fundCurrent(Iterable<Tx> txs, String fundId) => txs
    .where((t) => t.type == TxType.savingsContribution && t.savingsFundId == fundId)
    .fold(0, (a, t) => a + t.amount);
