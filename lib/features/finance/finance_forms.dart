import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/draft.dart';
import '../../core/widgets/entity_editor.dart';
import '../../core/widgets/format.dart';
import '../../core/design/theme.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';

/// Which finance entity the route-selected id refers to: `/finance/tx:<id>` or `/finance/fund:<id>`.
String txRoute(String? id) => '/finance/tx:${id ?? 'new'}';
String fundRoute(String? id) => '/finance/fund:${id ?? 'new'}';

void openTransaction(BuildContext context, {String? id}) {
  if (MediaQuery.sizeOf(context).width >= 840) {
    context.go(txRoute(id));
  } else {
    showEntitySheet(context, builder: (_) => TransactionForm(txId: id, presentation: EditorPresentation.sheet));
  }
}

void openFund(BuildContext context, {String? id}) {
  if (MediaQuery.sizeOf(context).width >= 840) {
    context.go(fundRoute(id));
  } else {
    showEntitySheet(context, builder: (_) => FundForm(fundId: id, presentation: EditorPresentation.sheet));
  }
}

String typeLabel(L10n l, TxType t) => switch (t) { TxType.income => l.txIncome, TxType.expense => l.txExpense, TxType.savingsContribution => l.txSaved };

class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({super.key, this.txId, required this.presentation, this.onClosed});
  final String? txId;
  final EditorPresentation presentation;
  final VoidCallback? onClosed;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> with DraftFormMixin<TransactionForm> {
  final _amount = TextEditingController();
  final _category = TextEditingController();
  final _note = TextEditingController();
  TxType _type = TxType.expense;
  DateTime _date = dateOnly(DateTime.now());
  String? _fundId;
  Tx? _original;
  bool _loaded = false;

  @override
  String get draftKey => 'tx:${widget.txId ?? 'new'}';
  @override
  bool get isDirtyDraft => _dirty;
  @override
  Map<String, Object?> snapshot() => {'amount': _amount.text, 'category': _category.text, 'note': _note.text, 'type': _type, 'date': _date, 'fund': _fundId};
  @override
  void restore(Map<String, Object?> d) {
    _amount.text = d['amount'] as String? ?? '';
    _category.text = d['category'] as String? ?? '';
    _note.text = d['note'] as String? ?? '';
    _type = d['type'] as TxType? ?? TxType.expense;
    _date = d['date'] as DateTime? ?? _date;
    _fundId = d['fund'] as String?;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.txId;
    if (id != null) {
      final all = await ref.read(financeRepoProvider).watchTransactions().first;
      final t = all.where((e) => e.id == id).firstOrNull;
      if (t != null) {
        _original = t;
        _amount.text = '${t.amount}';
        _category.text = t.category;
        _note.text = t.note;
        _type = t.type;
        _date = t.date;
        _fundId = t.savingsFundId;
      }
    }
    loadDraft();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _amountValue => int.tryParse(_amount.text.trim());

  bool get _dirty {
    final o = _original;
    if (o == null) return _amount.text.isNotEmpty || _category.text.isNotEmpty || _note.text.isNotEmpty || _type != TxType.expense;
    return _amountValue != o.amount || _category.text != o.category || _note.text != o.note || _type != o.type || _date != o.date || _fundId != o.savingsFundId;
  }

  Future<void> _save() async {
    final repo = ref.read(financeRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    final amount = _amountValue ?? 0;
    if (widget.txId != null) {
      await repo.updateTransaction(widget.txId!, amount: amount, type: _type, category: _category.text, note: _note.text, date: _date, savingsFundId: _fundId);
    } else {
      final id = await repo.createTransaction(amount: amount, type: _type, category: _category.text, note: _note.text, date: _date, savingsFundId: _fundId);
      showUndoSnackOn(messenger, l.entityAdded(l.quickAddTransaction), undoLabel: l.undo, onUndo: () => repo.deleteTransaction(id));
    }
    discardDraft();
  }

  Future<void> _delete() async {
    final o = _original;
    if (o == null) return;
    final repo = ref.read(financeRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    await repo.deleteTransaction(o.id);
    discardDraft();
    showUndoSnackOn(messenger, l.entityDeleted(l.quickAddTransaction), undoLabel: l.undo, onUndo: () => repo.restoreTransaction(o));
    if (!mounted) return;
    if (widget.presentation == EditorPresentation.inline) {
      widget.onClosed?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
    final l = L10n.of(context);
    final fmt = ref.watch(formatDateProvider);
    final funds = ref.watch(fundsProvider).asData?.value ?? const <SavingsFund>[];
    final txs = ref.watch(transactionsProvider).asData?.value ?? const <Tx>[];
    // Recently used categories (most recent first) as suggestion chips.
    final recent = <String>[];
    for (final t in txs) {
      final c = t.category.trim();
      if (c.isNotEmpty && !recent.contains(c)) recent.add(c);
      if (recent.length >= 6) break;
    }
    return EntityEditor(
      presentation: widget.presentation,
      title: widget.txId == null ? l.txNew : l.txEdit,
      dirty: _dirty,
      valid: (_amountValue ?? 0) >= 1,
      onSave: _save,
      onDelete: widget.txId == null ? null : _delete,
      onClosed: () {
        discardDraft();
        widget.onClosed?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _amount,
            autofocus: widget.presentation == EditorPresentation.sheet,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: moneyStyle(Theme.of(context).textTheme.headlineMedium),
            decoration: InputDecoration(labelText: l.fieldAmount),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.md),
          SegmentedButton<TxType>(
            showSelectedIcon: false,
            segments: [for (final t in TxType.values) ButtonSegment(value: t, label: Text(typeLabel(l, t)))],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              if (_type != TxType.savingsContribution) _fundId = null;
            }),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _category,
            decoration: InputDecoration(labelText: l.fieldCategory),
            onChanged: (_) => setState(() {}),
          ),
          if (recent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Wrap(spacing: Space.sm, runSpacing: Space.xs, children: [
                for (final c in recent) ActionChip(label: Text(c), onPressed: () => setState(() => _category.text = c)),
              ]),
            ),
          MoreDetails(
            initiallyOpen: _note.text.isNotEmpty || _fundId != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(fmt(_date)),
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (d != null) setState(() => _date = dateOnly(d));
                  },
                ),
                const SizedBox(height: Space.md),
                TextField(controller: _note, decoration: InputDecoration(labelText: l.fieldNote), onChanged: (_) => setState(() {})),
                const SizedBox(height: Space.md),
                DropdownButtonFormField<String?>(
                  initialValue: funds.any((f) => f.id == _fundId) ? _fundId : null,
                  decoration: InputDecoration(labelText: l.fieldSavingsFund),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(l.none)),
                    for (final f in funds) DropdownMenuItem<String?>(value: f.id, child: Text(f.name)),
                  ],
                  onChanged: _type == TxType.savingsContribution ? (v) => setState(() => _fundId = v) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FundForm extends ConsumerStatefulWidget {
  const FundForm({super.key, this.fundId, required this.presentation, this.onClosed});
  final String? fundId;
  final EditorPresentation presentation;
  final VoidCallback? onClosed;

  @override
  ConsumerState<FundForm> createState() => _FundFormState();
}

class _FundFormState extends ConsumerState<FundForm> with DraftFormMixin<FundForm> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  SavingsFund? _original;
  bool _loaded = false;

  @override
  String get draftKey => 'fund:${widget.fundId ?? 'new'}';
  @override
  bool get isDirtyDraft => _dirty;
  @override
  Map<String, Object?> snapshot() => {'name': _name.text, 'target': _target.text};
  @override
  void restore(Map<String, Object?> d) {
    _name.text = d['name'] as String? ?? '';
    _target.text = d['target'] as String? ?? '';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.fundId;
    if (id != null) {
      final all = await ref.read(financeRepoProvider).watchFunds().first;
      final f = all.where((e) => e.id == id).firstOrNull;
      if (f != null) {
        _original = f;
        _name.text = f.name;
        _target.text = '${f.targetAmount}';
      }
    }
    loadDraft();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  int? get _targetValue => int.tryParse(_target.text.trim());

  bool get _dirty {
    final o = _original;
    if (o == null) return _name.text.isNotEmpty || _target.text.isNotEmpty;
    return _name.text != o.name || _targetValue != o.targetAmount;
  }

  Future<void> _save() async {
    final repo = ref.read(financeRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    if (widget.fundId != null) {
      await repo.updateFund(widget.fundId!, name: _name.text, targetAmount: _targetValue ?? 0);
    } else {
      final id = await repo.createFund(name: _name.text, targetAmount: _targetValue ?? 0);
      showUndoSnackOn(messenger, l.entityAdded(l.entityFund), undoLabel: l.undo, onUndo: () => repo.deleteFund(id));
    }
    discardDraft();
  }

  Future<void> _delete() async {
    final o = _original;
    if (o == null) return;
    final l = L10n.of(context);
    final ok = await confirmDelete(
      context,
      title: l.fundDeleteTitle,
      body: l.fundDeleteBody(o.name),
    );
    if (!ok || !mounted) return;
    await ref.read(financeRepoProvider).deleteFund(o.id);
    discardDraft();
    if (!mounted) return;
    if (widget.presentation == EditorPresentation.inline) {
      widget.onClosed?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
    final l = L10n.of(context);
    return EntityEditor(
      presentation: widget.presentation,
      title: widget.fundId == null ? l.fundNew : l.fundEdit,
      dirty: _dirty,
      valid: _name.text.trim().isNotEmpty && (_targetValue ?? 0) >= 1,
      onSave: _save,
      onDelete: widget.fundId == null ? null : _delete,
      onClosed: () {
        discardDraft();
        widget.onClosed?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: widget.presentation == EditorPresentation.sheet,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.name),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _target,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l.fieldTargetAmount),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
