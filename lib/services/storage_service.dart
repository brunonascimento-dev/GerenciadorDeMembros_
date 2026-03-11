import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadMemberPhoto(File file) async {
    try {
      // Cria um nome único para a imagem
      final String fileName = '${const Uuid().v4()}.jpg';
      final Reference ref = _storage.ref().child('member_photos/$fileName');

      // Faz o upload
      final UploadTask task = ref.putFile(file);
      final TaskSnapshot snapshot = await task;

      // Retorna a URL pública para salvar no banco
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      developer.log('Erro no upload: $e', name: 'StorageService');
      return null;
    }
  }
}
