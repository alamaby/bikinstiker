import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/sticker_pack.dart';
import '../../../data/models/sticker_pack_item.dart';
import '../../../data/repositories/sticker_pack_repository.dart';

sealed class StickerPackEvent extends Equatable {
  const StickerPackEvent();
  @override
  List<Object?> get props => [];
}

/// Load (or refresh) the list of accessible packs.
class StickerPackLoadRequested extends StickerPackEvent {
  const StickerPackLoadRequested();
}

/// Load details (including items) for a specific pack.
class StickerPackDetailLoadRequested extends StickerPackEvent {
  final String packId;
  const StickerPackDetailLoadRequested(this.packId);
  @override
  List<Object?> get props => [packId];
}

/// Create a new pack.
class StickerPackCreateRequested extends StickerPackEvent {
  final String name;
  const StickerPackCreateRequested(this.name);
  @override
  List<Object?> get props => [name];
}

/// Add a sticker to a pack.
class StickerPackAddStickerRequested extends StickerPackEvent {
  final String packId;
  final String stickerId;
  final List<String> emojis;
  final String? accessibilityText;

  const StickerPackAddStickerRequested({
    required this.packId,
    required this.stickerId,
    required this.emojis,
    this.accessibilityText,
  });

  @override
  List<Object?> get props => [packId, stickerId, emojis, accessibilityText];
}

/// Remove a sticker from a pack.
class StickerPackRemoveStickerRequested extends StickerPackEvent {
  final String packId;
  final String stickerId;
  const StickerPackRemoveStickerRequested(this.packId, this.stickerId);
  @override
  List<Object?> get props => [packId, stickerId];
}

/// Rename a pack.
class StickerPackRenameRequested extends StickerPackEvent {
  final String packId;
  final String newName;
  const StickerPackRenameRequested(this.packId, this.newName);
  @override
  List<Object?> get props => [packId, newName];
}

/// Delete (soft) a pack.
class StickerPackDeleteRequested extends StickerPackEvent {
  final String packId;
  const StickerPackDeleteRequested(this.packId);
  @override
  List<Object?> get props => [packId];
}

/// Set tray icon from a source sticker.
class StickerPackSetTrayIconRequested extends StickerPackEvent {
  final String packId;
  final String sourceStickerId;
  const StickerPackSetTrayIconRequested(this.packId, this.sourceStickerId);
  @override
  List<Object?> get props => [packId, sourceStickerId];
}

/// Clear the current error message (called from screen after snackbar shown).
class StickerPackErrorCleared extends StickerPackEvent {
  const StickerPackErrorCleared();
}

/// Clear the selected pack after navigation away from detail screen.
class StickerPackDetailCleared extends StickerPackEvent {
  const StickerPackDetailCleared();
}

enum StickerPackStatus { initial, loading, loaded, error }

class StickerPackState extends Equatable {
  final StickerPackStatus status;
  final List<StickerPack> packs;
  final int slotCap;
  final String? errorMessage;
  final Set<String> pendingPackIds;

  // Detail (single pack view)
  final StickerPack? selectedPack;
  final List<StickerPackItem> selectedPackItems;
  final StickerPackStatus detailStatus;
  final bool isDetailLoading;

  const StickerPackState({
    this.status = StickerPackStatus.initial,
    this.packs = const [],
    this.slotCap = 2,
    this.errorMessage,
    this.pendingPackIds = const {},
    this.selectedPack,
    this.selectedPackItems = const [],
    this.detailStatus = StickerPackStatus.initial,
    this.isDetailLoading = false,
  });

  int get activeCount => packs.where((p) => p.isActive && !p.isLocked).length;

  bool isAtCapacity() => activeCount >= slotCap;

  bool isPackPending(String packId) => pendingPackIds.contains(packId);

  static const Object _undefined = Object();

  StickerPackState copyWith({
    StickerPackStatus? status,
    List<StickerPack>? packs,
    int? slotCap,
    String? errorMessage,
    Set<String>? pendingPackIds,
    StickerPack? selectedPack,
    List<StickerPackItem>? selectedPackItems,
    StickerPackStatus? detailStatus,
    bool? isDetailLoading,
  }) {
    return StickerPackState(
      status: status ?? this.status,
      packs: packs ?? this.packs,
      slotCap: slotCap ?? this.slotCap,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage,
      pendingPackIds: pendingPackIds ?? this.pendingPackIds,
      selectedPack: selectedPack ?? this.selectedPack,
      selectedPackItems: selectedPackItems ?? this.selectedPackItems,
      detailStatus: detailStatus ?? this.detailStatus,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
    );
  }

  @override
  List<Object?> get props => [
    status,
    packs,
    slotCap,
    errorMessage,
    pendingPackIds,
    selectedPack,
    selectedPackItems,
    detailStatus,
    isDetailLoading,
  ];
}

class StickerPackBloc extends Bloc<StickerPackEvent, StickerPackState> {
  final StickerPackRepository _repo;

  StickerPackBloc(this._repo) : super(const StickerPackState()) {
    on<StickerPackLoadRequested>(_onLoad);
    on<StickerPackDetailLoadRequested>(_onDetailLoad);
    on<StickerPackCreateRequested>(_onCreate);
    on<StickerPackAddStickerRequested>(_onAddSticker);
    on<StickerPackRemoveStickerRequested>(_onRemoveSticker);
    on<StickerPackRenameRequested>(_onRename);
    on<StickerPackDeleteRequested>(_onDelete);
    on<StickerPackSetTrayIconRequested>(_onSetTrayIcon);
    on<StickerPackErrorCleared>(_onErrorCleared);
    on<StickerPackDetailCleared>(_onDetailCleared);
  }

  Future<void> _onLoad(
    StickerPackLoadRequested event,
    Emitter<StickerPackState> emit,
  ) async {
    emit(state.copyWith(status: StickerPackStatus.loading));
    try {
      final packs = await _repo.fetchUserPacks();
      emit(state.copyWith(status: StickerPackStatus.loaded, packs: packs));
    } catch (e) {
      emit(
        state.copyWith(
          status: StickerPackStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDetailLoad(
    StickerPackDetailLoadRequested event,
    Emitter<StickerPackState> emit,
  ) async {
    emit(
      state.copyWith(
        detailStatus: StickerPackStatus.loading,
        isDetailLoading: true,
      ),
    );
    try {
      final result = await _repo.getPackDetail(event.packId);
      emit(
        state.copyWith(
          detailStatus: StickerPackStatus.loaded,
          selectedPack: result.pack,
          selectedPackItems: result.items,
          isDetailLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          detailStatus: StickerPackStatus.error,
          errorMessage: e.toString(),
          isDetailLoading: false,
        ),
      );
    }
  }

  Future<void> _onCreate(
    StickerPackCreateRequested event,
    Emitter<StickerPackState> emit,
  ) async {
    try {
      await _repo.createPack(event.name);
      // Reload list to include new pack
      add(const StickerPackLoadRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onAddSticker(
    StickerPackAddStickerRequested event,
    Emitter<StickerPackState> emit,
  ) async {
    final pendingKey = '${event.packId}:${event.stickerId}';
    emit(state.copyWith(pendingPackIds: {...state.pendingPackIds, pendingKey}));
    try {
      await _repo.addStickerToPack(
        packId: event.packId,
        stickerId: event.stickerId,
        emojis: event.emojis,
        accessibilityText: event.accessibilityText,
      );
      final newPending = {...state.pendingPackIds}..remove(pendingKey);
      emit(state.copyWith(pendingPackIds: newPending));
      // Refresh detail if viewing this pack, and the list
      if (state.selectedPack?.id == event.packId) {
        add(StickerPackDetailLoadRequested(event.packId));
      }
      add(const StickerPackLoadRequested());
    } catch (e) {
      final newPending = {...state.pendingPackIds}..remove(pendingKey);
      emit(
        state.copyWith(pendingPackIds: newPending, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onRemoveSticker(
    StickerPackRemoveStickerRequested event,
    Emitter<StickerPackState> emit,
  ) async {
    final pendingKey = '${event.packId}:${event.stickerId}';
    emit(state.copyWith(pendingPackIds: {...state.pendingPackIds, pendingKey}));
    try {
      await _repo.removeStickerFromPack(
        packId: event.packId,
        stickerId: event.stickerId,
      );
      final newPending = {...state.pendingPackIds}..remove(pendingKey);
      emit(state.copyWith(pendingPackIds: newPending));
      if (state.selectedPack?.id == event.packId) {
        add(StickerPackDetailLoadRequested(event.packId));
      }
      add(const StickerPackLoadRequested());
    } catch (e) {
      final newPending = {...state.pendingPackIds}..remove(pendingKey);
      emit(
        state.copyWith(pendingPackIds: newPending, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onRename(
    StickerPackRenameRequested event,
    Emitter<StickerPackState> emit,
  ) async {
    try {
      await _repo.renamePack(packId: event.packId, newName: event.newName);
      add(const StickerPackLoadRequested());
      if (state.selectedPack?.id == event.packId) {
        add(StickerPackDetailLoadRequested(event.packId));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDelete(
    StickerPackDeleteRequested event,
    Emitter<StickerPackState> emit,
  ) async {
    try {
      await _repo.deletePack(event.packId);
      add(const StickerPackLoadRequested());
      if (state.selectedPack?.id == event.packId) {
        add(const StickerPackDetailCleared());
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onSetTrayIcon(
    StickerPackSetTrayIconRequested event,
    Emitter<StickerPackState> emit,
  ) async {
    try {
      await _repo.setTrayIcon(
        packId: event.packId,
        sourceStickerId: event.sourceStickerId,
      );
      if (state.selectedPack?.id == event.packId) {
        add(StickerPackDetailLoadRequested(event.packId));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onErrorCleared(
    StickerPackErrorCleared event,
    Emitter<StickerPackState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
  }

  void _onDetailCleared(
    StickerPackDetailCleared event,
    Emitter<StickerPackState> emit,
  ) {
    emit(
      state.copyWith(
        selectedPack: null,
        selectedPackItems: const [],
        detailStatus: StickerPackStatus.initial,
        isDetailLoading: false,
      ),
    );
  }
}
