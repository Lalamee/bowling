import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum SearchDomain {
  all,
  orders,
  parts,
  clubs,
  knowledge,
  users,
}

extension SearchDomainExt on SearchDomain {
  String get label {
    switch (this) {
      case SearchDomain.orders:
        return 'Заказы';
      case SearchDomain.parts:
        return 'Запчасти';
      case SearchDomain.clubs:
        return 'Клубы';
      case SearchDomain.knowledge:
        return 'База знаний';
      case SearchDomain.users:
        return 'Пользователи';
      case SearchDomain.all:
        return 'Все';
    }
  }

  IconData get icon {
    switch (this) {
      case SearchDomain.orders:
        return Icons.assignment_outlined;
      case SearchDomain.parts:
        return Icons.handyman_outlined;
      case SearchDomain.clubs:
        return Icons.storefront_outlined;
      case SearchDomain.knowledge:
        return Icons.menu_book_outlined;
      case SearchDomain.users:
        return Icons.person_search_outlined;
      case SearchDomain.all:
        return Icons.travel_explore_outlined;
    }
  }
}

class SearchItem extends Equatable {
  final SearchDomain domain;
  final String id;
  final String title;
  final String subtitle;
  final String? trailing;
  final String? highlight;

  const SearchItem({
    required this.domain,
    required this.id,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.highlight,
  });

  SearchItem copyWith({
    SearchDomain? domain,
    String? id,
    String? title,
    String? subtitle,
    String? trailing,
    String? highlight,
  }) {
    return SearchItem(
      domain: domain ?? this.domain,
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      trailing: trailing ?? this.trailing,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  List<Object?> get props => [domain, id, title, subtitle, trailing, highlight];
}

class SearchResultPage {
  final List<SearchItem> items;
  final int page;
  final bool hasMore;
  final int totalCount;

  const SearchResultPage({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.totalCount,
  });
}

