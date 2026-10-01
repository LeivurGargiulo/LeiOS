import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';

/// Declarative description of a Lists tab (spec §10.6): one implementation, four configs.
class ListConfig {
  const ListConfig({
    required this.kind,
    required this.icon,
    this.hasCategory = false,
    this.categorySuggestions = const [],
    this.hasNotes = true,
    this.hasUrl = true,
    this.hasPrice = false,
  });

  final ListKind kind;
  final IconData icon;
  final bool hasCategory;
  final List<String> categorySuggestions;
  final bool hasNotes;
  final bool hasUrl;
  final bool hasPrice;

  String tabLabel(L10n l) => switch (kind) {
        ListKind.media => l.listTabMedia,
        ListKind.wishlist => l.listTabWishlist,
        ListKind.dream => l.listTabDreams,
        ListKind.learning => l.listTabLearning,
      };

  String doneLabel(L10n l) => switch (kind) {
        ListKind.media || ListKind.dream => l.statusDone,
        ListKind.wishlist => l.listDonePurchased,
        ListKind.learning => l.listDoneLearned,
      };

  String? categoryLabel(L10n l) => switch (kind) {
        ListKind.media => l.listCategoryKind,
        ListKind.wishlist => l.listCategoryCategory,
        ListKind.dream => null,
        ListKind.learning => l.listCategoryArea,
      };

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
    icon: Icons.movie_outlined,
    hasCategory: true,
    categorySuggestions: ['movie', 'series', 'book', 'game', 'other'],
  ),
  ListConfig(
    kind: ListKind.wishlist,
    icon: Icons.card_giftcard,
    hasCategory: true,
    hasPrice: true,
  ),
  ListConfig(
    kind: ListKind.dream,
    icon: Icons.auto_awesome,
    hasNotes: false,
    hasUrl: false,
  ),
  ListConfig(
    kind: ListKind.learning,
    icon: Icons.school_outlined,
    hasCategory: true,
  ),
];
