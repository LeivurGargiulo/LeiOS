import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/screen_scaffold.dart';
import '../../core/design/breakpoints.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entity_editor.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/master_detail_scaffold.dart';
import '../../core/widgets/period_picker.dart';
import '../../core/widgets/small_widgets.dart';
import '../../core/widgets/swipe_action_tile.dart';
import '../../core/widgets/tabbed_screen.dart';
import '../../domain/dates.dart';
import '../../domain/finance.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import 'finance_forms.dart';

enum _TypeFilter { all, income, expense, saved }

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key, this.selected});

  /// `tx:<id|new>` or `fund:<id|new>`.
  final String? selected;

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  int _tab = 0;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  _TypeFilter _filter = _TypeFilter.all;

  String? get _selTx => widget.selected?.startsWith('tx:') == true ? widget.selected!.substring(3) : null;
  String? get _selFund => widget.selected?.startsWith('fund:') == true ? widget.selected!.substring(5) : null;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return ScreenScaffold(
      title: l.navFinances,
      fab: FabSpec(
        tooltip: _tab == 0 ? l.emptyTransactionsAction : l.emptyFundsAction,
        onPressed: () => _tab == 0 ? openTransaction(context) : openFund(context),
      ),
      body: TabbedScreen(
        prefKey: 'finance',
        onTabChanged: (i) {
          if (i != _tab) setState(() => _tab = i);
        },
        tabs: [
          TabSpec(label: l.financeTransactions, builder: (_) => _transactionsTab(context)),
          TabSpec(label: l.financeSavingsFunds, builder: (_) => _fundsTab(context)),
        ],
      ),
    );
  }

  Widget _typeFilterRow() {
    final l = L10n.of(context);
    return ChipFilterRow<_TypeFilter>(
      values: _TypeFilter.values,
      selected: _filter,
      labelOf: (f) => switch (f) { _TypeFilter.all => l.all, _TypeFilter.income => l.txIncome, _TypeFilter.expense => l.txExpense, _TypeFilter.saved => l.txSaved },
      onSelected: (f) => setState(() => _filter = f),
    );
  }

  bool _matches(Tx t) => switch (_filter) {
        _TypeFilter.all => true,
        _TypeFilter.income => t.type == TxType.income,
        _TypeFilter.expense => t.type == TxType.expense,
        _TypeFilter.saved => t.type == TxType.savingsContribution,
      };

  // ---------------- Transactions ----------------

  Widget _transactionsTab(BuildContext context) {
    final l = L10n.of(context);
    final async = ref.watch(transactionsProvider);
    final all = async.asData?.value ?? const <Tx>[];
    final summary = monthlySummary(all, _month.year, _month.month);
    final monthTxs = all.where((t) => t.date.year == _month.year && t.date.month == _month.month && _matches(t)).toList();
    final selected = _selTx;

    final master = ListView(
      padding: const EdgeInsets.only(bottom: kListBottomPadding),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.sm),
          child: _SummaryCard(month: _month, summary: summary, onMonth: (m) => setState(() => _month = m), expandedNew: context.isExpanded ? () => context.go(txRoute(null)) : null),
        ),
        _typeFilterRow(),
        if (async.isLoading && !async.hasValue)
          const Padding(padding: EdgeInsets.all(Space.xl), child: Center(child: CircularProgressIndicator()))
        else if (monthTxs.isEmpty)
          SizedBox(
            height: 300,
            child: EmptyState(icon: Icons.account_balance_wallet, title: l.emptyTransactionsTitle, message: l.emptyTransactionsMessage, actionLabel: l.emptyTransactionsAction, onAction: () => openTransaction(context), seed: 20),
          )
        else
          ..._grouped(context, monthTxs, selected),
      ],
    );

    return MasterDetailScaffold<Tx>(
      master: master,
      detail: selected == null
          ? null
          : TransactionForm(key: ValueKey('tx-form-$selected'), txId: selected == 'new' ? null : selected, presentation: EditorPresentation.inline, onClosed: () => context.go('/finance')),
      itemIds: [for (final t in all) t.id],
      selectedId: selected,
      dataLoaded: async.hasValue,
      onSelectionCleared: () => context.go('/finance'),
      onCreate: () => context.go(txRoute(null)),
      onMoveSelection: (dir) {
        if (monthTxs.isEmpty) return;
        final i = monthTxs.indexWhere((t) => t.id == selected);
        context.go(txRoute(monthTxs[(i + dir).clamp(0, monthTxs.length - 1)].id));
      },
    );
  }

  List<Widget> _grouped(BuildContext context, List<Tx> txs, String? selected) {
    final fmt = ref.watch(formatDateProvider);
    final out = <Widget>[];
    DateTime? last;
    for (final t in txs) {
      if (last == null || !sameDay(last, t.date)) {
        out.add(SectionHeader(fmt(t.date)));
        last = t.date;
      }
      out.add(_TxTile(tx: t, selected: t.id == selected));
    }
    return out;
  }

  // ---------------- Funds ----------------

  Widget _fundsTab(BuildContext context) {
    final l = L10n.of(context);
    final fundsAsync = ref.watch(fundsProvider);
    final funds = fundsAsync.asData?.value ?? const <SavingsFund>[];
    final txs = ref.watch(transactionsProvider).asData?.value ?? const <Tx>[];
    final selected = _selFund;

    final master = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (context.isExpanded)
          Padding(padding: const EdgeInsets.all(Space.sm), child: Align(alignment: Alignment.centerRight, child: NewButton(onPressed: () => context.go(fundRoute(null))))),
        Expanded(
          child: fundsAsync.isLoading && !fundsAsync.hasValue
              ? const Center(child: CircularProgressIndicator())
              : funds.isEmpty
                  ? EmptyState(icon: Icons.savings, title: l.emptyFundsTitle, message: l.emptyFundsMessage, actionLabel: l.emptyFundsAction, onAction: () => openFund(context), seed: 21)
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: kListBottomPadding),
                      itemCount: funds.length,
                      separatorBuilder: (_, _) => const Divider(indent: Space.lg),
                      itemBuilder: (context, i) {
                        final l = L10n.of(context);
                        final f = funds[i];
                        final current = fundCurrent(txs, f.id);
                        final pct = fundProgress(current, f.targetAmount);
                        return ListTile(
                          selected: f.id == selected,
                          selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
                          title: Text(f.name),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: Space.xs),
                            child: LabeledProgress(percent: pct, color: Theme.of(context).colorScheme.tertiary, semanticsLabel: l.fundProgressOf(f.name)),
                          ),
                          trailing: Text('${formatMoney(current)} / ${formatMoney(f.targetAmount)}', style: moneyStyle(Theme.of(context).textTheme.bodyMedium)),
                          onTap: () => context.isExpanded ? context.go(fundRoute(f.id)) : openFund(context, id: f.id),
                        );
                      },
                    ),
        ),
      ],
    );

    return MasterDetailScaffold<SavingsFund>(
      master: master,
      detail: selected == null
          ? null
          : FundForm(key: ValueKey('fund-form-$selected'), fundId: selected == 'new' ? null : selected, presentation: EditorPresentation.inline, onClosed: () => context.go('/finance')),
      itemIds: [for (final f in funds) f.id],
      selectedId: selected,
      dataLoaded: fundsAsync.hasValue,
      onSelectionCleared: () => context.go('/finance'),
      onCreate: () => context.go(fundRoute(null)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.month, required this.summary, required this.onMonth, this.expandedNew});
  final DateTime month;
  final MonthlySummary summary;
  final ValueChanged<DateTime> onMonth;
  final VoidCallback? expandedNew;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxCat = summary.byCategory.isEmpty ? 1 : summary.byCategory.first.amount;
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: MonthSelector(month: month, onChanged: onMonth)),
              if (expandedNew != null) NewButton(onPressed: expandedNew!),
            ]),
            const SizedBox(height: Space.sm),
            Text(l.financeBalance, style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            Semantics(
              label: l.financeBalanceSemantics(summary.balance),
              excludeSemantics: true,
              child: Text(
                formatMoney(summary.balance),
                textAlign: TextAlign.center,
                style: moneyStyle(tt.displaySmall?.copyWith(color: summary.balance < 0 ? cs.error : cs.onSurface)),
              ),
            ),
            const SizedBox(height: Space.md),
            Row(children: [
              Expanded(child: StatTile(label: l.txIncome, value: formatMoney(summary.income), color: cs.primary)),
              const SizedBox(width: Space.sm),
              Expanded(child: StatTile(label: l.financeExpenses, value: formatMoney(summary.expenses), color: cs.error)),
              const SizedBox(width: Space.sm),
              Expanded(child: StatTile(label: l.txSaved, value: formatMoney(summary.saved), color: cs.tertiary)),
            ]),
            if (summary.byCategory.isNotEmpty) ...[
              SectionHeader(l.financeSpendingByCategory, padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm)),
              for (final c in summary.byCategory)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(c.category, style: tt.bodyMedium, overflow: TextOverflow.ellipsis)),
                      Text(formatMoney(c.amount), style: moneyStyle(tt.bodyMedium)),
                    ]),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(value: c.amount / maxCat, minHeight: 8, color: cs.error.withValues(alpha: 0.6)),
                  ]),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TxTile extends ConsumerWidget {
  const _TxTile({required this.tx, required this.selected});
  final Tx tx;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final repo = ref.read(financeRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    final (icon, color, sign) = switch (tx.type) {
      TxType.income => (Icons.arrow_downward, cs.primary, '+'),
      TxType.expense => (Icons.arrow_upward, cs.onSurface, '−'),
      TxType.savingsContribution => (Icons.savings, cs.tertiary, ''),
    };
    Future<void> delete() async {
      final t = tx;
      await repo.deleteTransaction(t.id);
      showUndoSnackOn(messenger, l.entityDeleted(l.quickAddTransaction), undoLabel: l.undo, onUndo: () => repo.restoreTransaction(t));
    }

    return SwipeActionTile(
      key: ValueKey('tx-${tx.id}'),
      onSwipeLeft: delete,
      menuItems: [TileMenuItem(label: l.delete, icon: Icons.delete_outline, destructive: true, onTap: delete)],
      child: ListTile(
        selected: selected,
        selectedTileColor: cs.secondaryContainer,
        leading: CircleAvatar(
          backgroundColor: cs.secondaryContainer,
          foregroundColor: cs.onSecondaryContainer,
          child: Icon(icon, semanticLabel: typeLabel(l, tx.type)),
        ),
        title: Text(tx.category.trim().isEmpty ? l.txUncategorized : tx.category),
        subtitle: tx.note.isEmpty ? null : Text(tx.note, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text('$sign${formatMoney(tx.amount)}', style: moneyStyle(tt.titleMedium?.copyWith(color: color))),
        onTap: () => context.isExpanded ? context.go(txRoute(tx.id)) : openTransaction(context, id: tx.id),
      ),
    );
  }
}

