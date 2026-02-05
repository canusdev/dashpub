import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dashpub_api/dashpub_api.dart';
import '../../../main.dart'; // for apiClient

class SettingsState {
  final GlobalSettings? settings;
  final bool isLoading;
  final String? error;

  const SettingsState({this.settings, this.isLoading = false, this.error});

  factory SettingsState.initial() => const SettingsState(isLoading: true);

  SettingsState copyWith({
    GlobalSettings? settings,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsState.initial()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      final settings = await apiClient.getSettings();
      emit(state.copyWith(settings: settings, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> updateSettings(GlobalSettings settings) async {
    // Optimistic update
    emit(state.copyWith(settings: settings));
    try {
      await apiClient.updateSettings(settings);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      // Revert if needed, or just reload
      loadSettings();
    }
  }
}
