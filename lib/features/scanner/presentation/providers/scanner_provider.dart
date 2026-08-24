import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/image_processor_service.dart';

/// ScannerState encapsulates image preprocessing parameters.
class ScannerState {
  final File? originalImage;
  final File? processedImage;
  final bool removeNoise;
  final bool deskew;
  final bool removeShadows;
  final bool enhanceContrast;
  final bool autoCrop;
  final bool enhanceQuality;
  final bool isProcessing;
  final String? errorMessage;

  ScannerState({
    this.originalImage,
    this.processedImage,
    this.removeNoise = true,
    this.deskew = true,
    this.removeShadows = true,
    this.enhanceContrast = true,
    this.autoCrop = true,
    this.enhanceQuality = true,
    this.isProcessing = false,
    this.errorMessage,
  });

  factory ScannerState.initial() {
    return ScannerState();
  }

  ScannerState copyWith({
    File? originalImage,
    File? processedImage,
    bool? removeNoise,
    bool? deskew,
    bool? removeShadows,
    bool? enhanceContrast,
    bool? autoCrop,
    bool? enhanceQuality,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return ScannerState(
      originalImage: originalImage ?? this.originalImage,
      processedImage: processedImage ?? this.processedImage,
      removeNoise: removeNoise ?? this.removeNoise,
      deskew: deskew ?? this.deskew,
      removeShadows: removeShadows ?? this.removeShadows,
      enhanceContrast: enhanceContrast ?? this.enhanceContrast,
      autoCrop: autoCrop ?? this.autoCrop,
      enhanceQuality: enhanceQuality ?? this.enhanceQuality,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
    );
  }
}

/// ScannerNotifier operates image preprocessing steps.
class ScannerNotifier extends StateNotifier<ScannerState> {
  final ImageProcessorService _imageProcessor;

  ScannerNotifier(this._imageProcessor) : super(ScannerState.initial());

  /// Sets the selected/captured image.
  void setImage(File file) {
    state = ScannerState(
      originalImage: file,
      processedImage: null,
      isProcessing: false,
    );
  }

  // Toggle Filters
  void toggleNoise() => state = state.copyWith(removeNoise: !state.removeNoise);
  void toggleDeskew() => state = state.copyWith(deskew: !state.deskew);
  void toggleShadows() => state = state.copyWith(removeShadows: !state.removeShadows);
  void toggleContrast() => state = state.copyWith(enhanceContrast: !state.enhanceContrast);
  void toggleAutoCrop() => state = state.copyWith(autoCrop: !state.autoCrop);
  void toggleQuality() => state = state.copyWith(enhanceQuality: !state.enhanceQuality);

  /// Performs OpenCV-style preprocessing.
  Future<File?> runPreprocessing() async {
    final original = state.originalImage;
    if (original == null) return null;

    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      final processed = await _imageProcessor.preprocessImage(
        original,
        removeNoise: state.removeNoise,
        deskew: state.deskew,
        removeShadows: state.removeShadows,
        enhanceContrast: state.enhanceContrast,
        autoCrop: state.autoCrop,
        enhanceQuality: state.enhanceQuality,
      );
      state = state.copyWith(processedImage: processed, isProcessing: false);
      return processed;
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: 'Preprocessing error: $e');
      return null;
    }
  }
}

/// Riverpod provider for Scanner state
final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  final processor = GetIt.I<ImageProcessorService>();
  return ScannerNotifier(processor);
});
