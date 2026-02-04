import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final String cloudName = "drq88lf6p";
  final String uploadPreset = "task_uploads";

  Future<String?> uploadImage(XFile pickedFile) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    // Leemos los bytes del archivo (compatible con Web y Móvil)
    final bytes = await pickedFile.readAsBytes();

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: pickedFile.name),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = utf8.decode(responseData);
      final jsonMap = jsonDecode(responseString);
      return jsonMap['secure_url'];
    }
    return null;
  }
}
