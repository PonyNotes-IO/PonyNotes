import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'file_library_models.dart';
import 'file_library_service.dart';

part 'file_library_bloc.freezed.dart';

class FileLibraryBloc extends Bloc<FileLibraryEvent, FileLibraryState> {
  FileLibraryBloc({
    FileLibraryService? service,
  })  : _service = service ?? FileLibraryService(),
        super(const FileLibraryState()) {
    on<FileLibraryEvent>(_onEvent);
  }

  final FileLibraryService _service;

  Future<void> _onEvent(
    FileLibraryEvent event,
    Emitter<FileLibraryState> emit,
  ) async {
    await event.when(
      started: () => _onStarted(emit),
      categoryChanged: (category) => _onCategoryChanged(category, emit),
      refreshFiles: () => _onRefreshFiles(emit),
      deleteFile: (fileId) => _onDeleteFile(fileId, emit),
    );
  }

  Future<void> _onStarted(Emitter<FileLibraryState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      final files = await _service.getAllFiles();
      emit(state.copyWith(
        isLoading: false,
        files: files,
        filteredFiles: files,
      ),);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ),);
    }
  }

  Future<void> _onCategoryChanged(
    FileLibraryCategory category,
    Emitter<FileLibraryState> emit,
  ) async {
    final filteredFiles = category == FileLibraryCategory.all
        ? state.files
        : state.files
            .where((file) => category.matchesFileType(file.fileType))
            .toList();

    emit(state.copyWith(
      selectedCategory: category,
      filteredFiles: filteredFiles,
    ),);
  }

  Future<void> _onRefreshFiles(Emitter<FileLibraryState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      final files = await _service.getAllFiles();
      final filteredFiles = state.selectedCategory == FileLibraryCategory.all
          ? files
          : files
              .where((file) =>
                  state.selectedCategory.matchesFileType(file.fileType),)
              .toList();

      emit(state.copyWith(
        isLoading: false,
        files: files,
        filteredFiles: filteredFiles,
        error: null,
      ),);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ),);
    }
  }

  Future<void> _onDeleteFile(
    String fileId,
    Emitter<FileLibraryState> emit,
  ) async {
    try {
      await _service.deleteFile(fileId);

      final updatedFiles = state.files.where((f) => f.id != fileId).toList();
      final filteredFiles = state.selectedCategory == FileLibraryCategory.all
          ? updatedFiles
          : updatedFiles
              .where((file) =>
                  state.selectedCategory.matchesFileType(file.fileType),)
              .toList();

      emit(state.copyWith(
        files: updatedFiles,
        filteredFiles: filteredFiles,
      ),);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}

@freezed
class FileLibraryEvent with _$FileLibraryEvent {
  const factory FileLibraryEvent.started() = _Started;
  const factory FileLibraryEvent.categoryChanged(FileLibraryCategory category) =
      _CategoryChanged;
  const factory FileLibraryEvent.refreshFiles() = _RefreshFiles;
  const factory FileLibraryEvent.deleteFile(String fileId) = _DeleteFile;
}

@freezed
class FileLibraryState with _$FileLibraryState {
  const factory FileLibraryState({
    @Default(FileLibraryCategory.all) FileLibraryCategory selectedCategory,
    @Default([]) List<FileLibraryItem> files,
    @Default([]) List<FileLibraryItem> filteredFiles,
    @Default(false) bool isLoading,
    String? error,
  }) = _FileLibraryState;
}
