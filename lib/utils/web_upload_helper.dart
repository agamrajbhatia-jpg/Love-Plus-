// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';

class WebUploadHelper {
  static Future<String?> pickImage() async {
    final completer = Completer<String?>();
    
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        // This generates a blob URL exactly like URL.createObjectURL in JS/React
        final url = html.Url.createObjectUrlFromBlob(file);
        completer.complete(url);
      } else {
        completer.complete(null);
      }
    });
    
    uploadInput.click();
    
    return completer.future;
  }
  static Future<WebImage?> pickImageWithBytes() async {
    final completer = Completer<WebImage?>();
    
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final url = html.Url.createObjectUrlFromBlob(file);
        
        final reader = html.FileReader();
        reader.onLoadEnd.listen((e) {
          completer.complete(WebImage(url, reader.result as Uint8List));
        });
        reader.readAsArrayBuffer(file);
      } else {
        completer.complete(null);
      }
    });
    
    uploadInput.click();
    
    return completer.future;
  }
}

class WebImage {
  final String url;
  final Uint8List bytes;
  WebImage(this.url, this.bytes);
}
