import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';

/// Declarative description of a Lists tab (spec §10.6): one implementation, four configs.
class ListConfig {
  const ListConfig({
    required this.kind,
    required this.tabLabel,
    required this.doneLabel,
    required this.icon,
    this.categoryLabel,
    this.categorySuggestions = const [],
    this.hasNotes = true,
    this.hasUrl = true,
    this.hasPrice = false,
  });

  final ListKind kind;
  final String tabLabel;
  final String doneLabel;
  final IconData icon;
  final String? categoryLabel;
  final List<String> categorySuggestions;
  final bool hasNotes;
  final bool hasUrl;
  final bool hasPrice;

  bool get hasCategory => categoryLabel != null;

  String emptyTitle(L10n l) => switch (kind) {
        ListKind.media => l.emptyMediaTitle,
        ListKind.wishlist => l.emptyWishlistTitle,
        ListKind.dream => l.emptyDreamsTitle,
        ListKind.learning => l.emptyLearningTitle,
      };

  String emptyMessage(L10n l) => switch (kind) {
        ListKind.media => l.emptyMediaMessage,
        ListKind.wishlist => l.emptyWishlistMessage,
        ListKind.dream => l.emptyDreamsMessage,
        ListKind.learning => l.emptyLearningMessage,
      };

  String emptyAction(L10n l) => kind == ListKind.dream ? l.emptyDreamsAction : l.emptyListAction;

  IconData get emptyIcon => switch (kind) {
        ListKind.media => Icons.movie_filter,
        ListKind.wishlist => Icons.card_giftcard,
        ListKind.dream => Icons.auto_awesome,
        ListKind.learning => Icons.school,
      };
}

const listConfigs = [
  ListConfig(
    kind: ListKind.media,
    tabLabel: 'Media',
    doneLabel: 'Done',
    icon: Icons.movie_outlined,
    categoryLabel: 'Kind',
    categorySuggestions: ['movie', 'series', 'book', 'game', 'other'],
  ),
  ListConfig(
    kind: ListKind.wishlist,
    tabLabel: 'Wishlist',
    doneLabel: 'Purchased',
    icon: Icons.card_giftcard,
    categoryLabel: 'Category',
    hasPrice: true,
  ),
  ListConfig(
    kind: ListKind.dream,
    tabLabel: 'Dreams',
    doneLabel: 'Done',
    icon: Icons.auto_awesome,
    hasNotes: false,
    hasUrl: false,
  ),
  ListConfig(
    kind: ListKind.learning,
    tabLabel: 'Learning',
    doneLabel: 'Learned',
    icon: Icons.school_outlined,
    categoryLabel: 'Area',
  ),
];
