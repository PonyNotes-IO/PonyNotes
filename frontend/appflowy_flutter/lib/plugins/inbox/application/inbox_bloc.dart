import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:appflowy/plugins/inbox/domain/models/inbox_item.dart';
import 'package:appflowy/plugins/inbox/domain/models/sort_option.dart';
import 'package:appflowy/plugins/inbox/application/inbox_service.dart';

part 'inbox_bloc.freezed.dart';

@freezed
class InboxEvent with _$InboxEvent {
  const factory InboxEvent.initial() = _Initial;
  const factory InboxEvent.loadItems() = _LoadItems;
  const factory InboxEvent.search(String query) = _Search;
  const factory InboxEvent.filterChanged(String filter) = _FilterChanged;
  const factory InboxEvent.sortChanged(SortOption sortOption) = _SortChanged;
  const factory InboxEvent.markAsRead(String itemId) = _MarkAsRead;
  const factory InboxEvent.markAllAsRead() = _MarkAllAsRead;
  const factory InboxEvent.toggleStar(String itemId) = _ToggleStar;
  const factory InboxEvent.toggleImportant(String itemId) = _ToggleImportant;
  const factory InboxEvent.deleteItem(String itemId) = _DeleteItem;
}

@freezed
class InboxState with _$InboxState {
  const factory InboxState({
    @Default([]) List<InboxItem> items,
    @Default([]) List<InboxItem> filteredItems,
    @Default('') String searchQuery,
    @Default('全部') String selectedFilter,
    @Default(SortOption.updatedDate) SortOption sortOption,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _InboxState;
}

class InboxBloc extends Bloc<InboxEvent, InboxState> {
  InboxBloc({
    required InboxService inboxService,
  })  : _inboxService = inboxService,
        super(const InboxState()) {
    on<InboxEvent>(
      (event, emit) async {
        await event.when(
          initial: () => _initial(emit),
          loadItems: () => _loadItems(emit),
          search: (query) => _search(emit, query),
          filterChanged: (filter) => _filterChanged(emit, filter),
          sortChanged: (sortOption) => _sortChanged(emit, sortOption),
          markAsRead: (itemId) => _markAsRead(emit, itemId),
          markAllAsRead: () => _markAllAsRead(emit),
          toggleStar: (itemId) => _toggleStar(emit, itemId),
          toggleImportant: (itemId) => _toggleImportant(emit, itemId),
          deleteItem: (itemId) => _deleteItem(emit, itemId),
        );
      },
    );
  }

  final InboxService _inboxService;

  Future<void> _initial(Emitter<InboxState> emit) async {
    emit(state.copyWith(isLoading: true));
    await _loadItems(emit);
  }

  Future<void> _loadItems(Emitter<InboxState> emit) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      final items = await _inboxService.loadItems();
      emit(state.copyWith(
        items: items,
        isLoading: false,
      ));
      _applyFiltersAndSort(emit);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _search(Emitter<InboxState> emit, String query) async {
    emit(state.copyWith(searchQuery: query));
    _applyFiltersAndSort(emit);
  }

  Future<void> _filterChanged(Emitter<InboxState> emit, String filter) async {
    emit(state.copyWith(selectedFilter: filter));
    _applyFiltersAndSort(emit);
  }

  Future<void> _sortChanged(Emitter<InboxState> emit, SortOption sortOption) async {
    emit(state.copyWith(sortOption: sortOption));
    _applyFiltersAndSort(emit);
  }

  Future<void> _markAsRead(Emitter<InboxState> emit, String itemId) async {
    try {
      await _inboxService.markAsRead(itemId);
      final updatedItems = state.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList();
      emit(state.copyWith(items: updatedItems));
      _applyFiltersAndSort(emit);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _markAllAsRead(Emitter<InboxState> emit) async {
    try {
      await _inboxService.markAllAsRead();
      final updatedItems = state.items.map((item) {
        return item.copyWith(isRead: true);
      }).toList();
      emit(state.copyWith(items: updatedItems));
      _applyFiltersAndSort(emit);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _toggleStar(Emitter<InboxState> emit, String itemId) async {
    try {
      final item = state.items.firstWhere((item) => item.id == itemId);
      await _inboxService.toggleStar(itemId, !item.isStarred);
      final updatedItems = state.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isStarred: !item.isStarred);
        }
        return item;
      }).toList();
      emit(state.copyWith(items: updatedItems));
      _applyFiltersAndSort(emit);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _toggleImportant(Emitter<InboxState> emit, String itemId) async {
    try {
      final item = state.items.firstWhere((item) => item.id == itemId);
      await _inboxService.toggleImportant(itemId, !item.isImportant);
      final updatedItems = state.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isImportant: !item.isImportant);
        }
        return item;
      }).toList();
      emit(state.copyWith(items: updatedItems));
      _applyFiltersAndSort(emit);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _deleteItem(Emitter<InboxState> emit, String itemId) async {
    try {
      await _inboxService.deleteItem(itemId);
      final updatedItems = state.items.where((item) => item.id != itemId).toList();
      emit(state.copyWith(items: updatedItems));
      _applyFiltersAndSort(emit);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _applyFiltersAndSort(Emitter<InboxState> emit) {
    var filteredItems = state.items.where((item) {
      // 应用搜索过滤
      final matchesSearch = state.searchQuery.isEmpty ||
          item.title.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          item.content.toLowerCase().contains(state.searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      // 应用类型过滤
      switch (state.selectedFilter) {
        case '未读':
          return !item.isRead;
        case '已收藏':
          return item.isStarred;
        case '重要':
          return item.isImportant;
        case '全部':
        default:
          return true;
      }
    }).toList();

    // 应用排序
    switch (state.sortOption) {
      case SortOption.updatedDate:
        filteredItems.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortOption.createdDate:
        filteredItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.title:
        filteredItems.sort((a, b) => a.title.compareTo(b.title));
        break;
              case SortOption.priority:
        filteredItems.sort((a, b) {
          if (a.isImportant && !b.isImportant) return -1;
          if (!a.isImportant && b.isImportant) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
    }

    emit(state.copyWith(filteredItems: filteredItems));
  }
} 