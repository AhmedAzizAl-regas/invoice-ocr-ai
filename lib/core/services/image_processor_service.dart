import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// ImageProcessorService coordinates noise reduction, contrast enhancement, shadow removal,
/// deskewing, auto-cropping, and quality tuning.
class ImageProcessorService {
  ImageProcessorService();

  /// Preprocesses an image based on the selected configuration flags.
  /// Executes heavy algorithms in a background isolate to keep UI responsive.
  Future<File> preprocessImage(
    File imageFile, {
    bool removeNoise = true,
    bool deskew = true,
    bool removeShadows = true,
    bool enhanceContrast = true,
    bool autoCrop = true,
    bool enhanceQuality = true,
  }) async {
    final bytes = await imageFile.readAsBytes();
    
    // Process the image in a compute isolate
    final processedBytes = await compute(_processImageIsolate, {
      'bytes': bytes,
      'removeNoise': removeNoise,
      'deskew': deskew,
      'removeShadows': removeShadows,
      'enhanceContrast': enhanceContrast,
      'autoCrop': autoCrop,
      'enhanceQuality': enhanceQuality,
    });

    // Save the preprocessed image to a temp file
    final tempDir = await getTemporaryDirectory();
    final fileName = 'preprocessed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final resultFile = File(p.join(tempDir.path, fileName));
    await resultFile.writeAsBytes(processedBytes);
    return resultFile;
  }

  /// Internal Isolate function processing the image pixels using dart:image.
  static Uint8List _processImageIsolate(Map<String, dynamic> params) {
    final Uint8List bytes = params['bytes'];
    final bool removeNoise = params['removeNoise'];
    final bool deskew = params['deskew'];
    final bool removeShadows = params['removeShadows'];
    final bool enhanceContrast = params['enhanceContrast'];
    final bool autoCrop = params['autoCrop'];
    final bool enhanceQuality = params['enhanceQuality'];

    // 1. Decode image
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // Scale down large camera images (e.g. 4000x3000) to max 1200px.
    // This reduces processing pixels by ~90%, preventing the isolate from lagging.
    if (image.width > 1200 || image.height > 1200) {
      final bool isWidthLarger = image.width > image.height;
      image = img.copyResize(
        image,
        width: isWidthLarger ? 1200 : null,
        height: isWidthLarger ? null : 1200,
      );
    }

    // 2. Deskew / Rotate if orientation requires it
    if (deskew) {
      // Basic deskewing checks image aspect ratios or EXIF details.
      // If it has standard horizontal skew, we rotate it slightly if detected (simplified here).
      // Standard camera images have orientation flags handled by image library.
      image = img.bakeOrientation(image);
    }

    // 3. Remove Shadows & Background extraction
    if (removeShadows) {
      // To subtract shadows: convert to greyscale, apply Gaussian blur to extract background lighting,
      // and divide the original image by the background lighting.
      final gray = img.grayscale(img.Image.from(image));
      final blurBg = img.gaussianBlur(img.Image.from(gray), radius: 30);
      
      // Perform division: pixel = (original / background) * 255
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final origPixel = image.getPixel(x, y);
          final bgPixel = blurBg.getPixel(x, y);
          
          final r = origPixel.r;
          final g = origPixel.g;
          final b = origPixel.b;
          final bgLuminance = bgPixel.luminance;

          if (bgLuminance > 0) {
            final newR = (r / bgLuminance * 255).clamp(0, 255).toInt();
            final newG = (g / bgLuminance * 255).clamp(0, 255).toInt();
            final newB = (b / bgLuminance * 255).clamp(0, 255).toInt();
            
            image.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
          }
        }
      }
    }

    // 4. Enhance Contrast
    if (enhanceContrast) {
      // Linearly stretch the contrast of the image pixels.
      image = img.adjustColor(
        image,
        contrast: 1.25,
        brightness: 1.05,
        saturation: 0.9, // Lower saturation helps OCR read text cleaner
      );
    }

    // 5. Remove Noise (Gaussian smoothing)
    if (removeNoise) {
      image = img.gaussianBlur(image, radius: 1);
    }

    // 6. Quality Enhancement / Sharpening
    if (enhanceQuality) {
      // Apply a convolution sharpen filter
      // Convolution filter for sharpening text:
      //  0  -1   0
      // -1   5  -1
      //  0  -1   0
      image = img.convolution(image, filter: [
         0, -1,  0,
        -1,  5, -1,
         0, -1,  0,
      ]);
    }

    // 7. Auto Crop (Invoice boundaries)
    if (autoCrop) {
      // Find bounding box containing content by searching for the boundaries of non-white pixels.
      // Since invoices usually sit in the center, we crop margins.
      // Simple bounding box thresholding:
      int minX = image.width;
      int maxX = 0;
      int minY = image.height;
      int maxY = 0;

      // Sample a grid of pixels to locate text regions (where contrast jumps)
      for (int y = 5; y < image.height - 5; y += 10) {
        for (int x = 5; x < image.width - 5; x += 10) {
          final pCurrent = image.getPixel(x, y);
          final pRight = image.getPixel(x + 2, y);
          final diff = (pCurrent.luminance - pRight.luminance).abs();
          
          // Contrast boundary detected (probable text region)
          if (diff > 0.15) {
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }

      // If a valid bounding box is found, crop with a padding margin
      if (maxX > minX && maxY > minY) {
        const padding = 20;
        final cropX = (minX - padding).clamp(0, image.width);
        final cropY = (minY - padding).clamp(0, image.height);
        final cropW = (maxX - minX + padding * 2).clamp(10, image.width - cropX);
        final cropH = (maxY - minY + padding * 2).clamp(10, image.height - cropY);

        if (cropW > image.width * 0.3 && cropH > image.height * 0.3) {
          image = img.copyCrop(image, x: cropX, y: cropY, width: cropW, height: cropH);
        }
      }
    }

    // 8. Return compressed JPG bytes for fast loading and OCR processing
    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }
}
