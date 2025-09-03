import 'package:appflowy/plugins/trash/application/trash_listener.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trash_bloc.freezed.dart';

class TrashBloc extends Bloc<TrashEvent, TrashState> {
  TrashBloc()
      : _service = TrashService(),
        _listener = TrashListener(),
        super(TrashState.init()) {
    _dispatch();
  }

  final TrashService _service;
  final TrashListener _listener;

  void _dispatch() {
    on<TrashEvent>((event, emit) async {
      await event.map(
        initial: (e) async {
          _listener.start(trashUpdated: _listenTrashUpdated);
          final result = await _service.readTrash();

          emit(
            result.fold(
              (object) => state.copyWith(
                objects: object.items,
                filteredObjects: object.items,
                successOrFailure: FlowyResult.success(null),
              ),
              (error) =>
                  state.copyWith(successOrFailure: FlowyResult.failure(error)),
            ),
          );
        },
        didReceiveTrash: (e) async {
          final filteredObjects = _filterObjects(e.trash, state.searchQuery);
          emit(state.copyWith(
            objects: e.trash,
            filteredObjects: filteredObjects,
          ));
        },
        search: (e) async {
          final filteredObjects = _filterObjects(state.objects, e.query);
          emit(state.copyWith(
            searchQuery: e.query,
            filteredObjects: filteredObjects,
          ));
        },
        putback: (e) async {
          final result = await TrashService.putback(e.trashId);
          await _handleResult(result, emit);
        },
        delete: (e) async {
          final result = await _service.deleteViews([e.trash.id]);
          await _handleResult(result, emit);
        },
        deleteAll: (e) async {
          final result = await _service.deleteAll();
          await _handleResult(result, emit);
        },
        restoreAll: (e) async {
          final result = await _service.restoreAll();
          await _handleResult(result, emit);
        },
      );
    });
  }

  List<TrashPB> _filterObjects(List<TrashPB> objects, String query) {
    if (query.isEmpty) {
      return objects;
    }
    
    final lowerQuery = query.toLowerCase();
    return objects.where((object) {
      final name = object.name.toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }

  Future<void> _handleResult(
    FlowyResult<dynamic, FlowyError> result,
    Emitter<TrashState> emit,
  ) async {
    emit(
      result.fold(
        (l) => state.copyWith(successOrFailure: FlowyResult.success(null)),
        (error) => state.copyWith(successOrFailure: FlowyResult.failure(error)),
      ),
    );
  }

  void _listenTrashUpdated(
    FlowyResult<List<TrashPB>, FlowyError> trashOrFailed,
  ) {
    trashOrFailed.fold(
      (trash) {
        add(TrashEvent.didReceiveTrash(trash));
      },
      (error) {
        Log.error(error);
      },
    );
  }

  @override
  Future<void> close() async {
    await _listener.close();
    return super.close();
  }
}

@freezed
class TrashEvent with _$TrashEvent {
  const factory TrashEvent.initial() = Initial;
  const factory TrashEvent.didReceiveTrash(List<TrashPB> trash) = ReceiveTrash;
  const factory TrashEvent.search(String query) = Search;
  const factory TrashEvent.putback(String trashId) = Putback;
  const factory TrashEvent.delete(TrashPB trash) = Delete;
  const factory TrashEvent.restoreAll() = RestoreAll;
  const factory TrashEvent.deleteAll() = DeleteAll;
}

@freezed
class TrashState with _$TrashState {
  const factory TrashState({
    required List<TrashPB> objects,
    required List<TrashPB> filteredObjects,
    required String searchQuery,
    required FlowyResult<void, FlowyError> successOrFailure,
  }) = _TrashState;

  factory TrashState.init() => TrashState(
        objects: [],
        filteredObjects: [],
        searchQuery: '',
        successOrFailure: FlowyResult.success(null),
      );
}
