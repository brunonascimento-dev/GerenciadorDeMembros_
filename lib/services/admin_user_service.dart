import 'package:cloud_functions/cloud_functions.dart';

class AdminUserService {
  final FirebaseFunctions _functions;

  AdminUserService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<void> createUser({
    required String email,
    required String password,
    required String role,
    String? congregationId,
  }) async {
    final callable = _functions.httpsCallable('adminCreateUser');
    await callable.call({
      'email': email,
      'password': password,
      'role': role,
      'congregationId': role == 'leader' ? congregationId : null,
    });
  }

  Future<void> updateUserProfile({
    required String uid,
    required String email,
    required String role,
    String? congregationId,
  }) async {
    final callable = _functions.httpsCallable('adminUpdateUserProfile');
    await callable.call({
      'uid': uid,
      'email': email,
      'role': role,
      'congregationId': role == 'leader' ? congregationId : null,
    });
  }

  Future<void> deleteUser(String uid) async {
    final callable = _functions.httpsCallable('adminDeleteUser');
    await callable.call({'uid': uid});
  }
}
