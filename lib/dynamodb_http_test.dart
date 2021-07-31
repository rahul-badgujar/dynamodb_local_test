import 'package:alfred/alfred.dart';
import 'package:crypto/crypto.dart';
import 'package:dynamodb_http_test/api/api.dart';
import 'package:dynamodb_http_test/utils/hashing/hashing.dart';

Future<void> run() async {
  final app = Alfred();

  app.all('example', (req, res) => 'Welcome to DynamoDB Test');

  // route to get details of user
  app.get('user/:uid', (req, res) async {
    try {
      final rawUid = req.params['uid'];
      final uid = int.tryParse(rawUid ?? '');
      if (uid == null) {
        throw Exception('uid not defined.');
      }
      final userData = await Api.instance.getUserDataWithUid(uid: uid);
      if (userData == null) {
        throw Exception('No user found for given uid [email:$uid]');
      }
      return {
        'status': 'success',
        'data': userData,
      };
    } on Exception catch (e) {
      return {'status': 'failure', 'error': e.toString()};
    }
  });

  app.get('userFromEmail/:email', (req, res) async {
    try {
      final email = req.params['email'];
      if (email == null) {
        throw Exception('email not defined.');
      }
      final userData = await Api.instance.getUserDataWithEmail(email: email);
      if (userData == null) {
        throw Exception('No user found for given email [email:$email]');
      }
      return {
        'status': 'success',
        'data': userData,
      };
    } on Exception catch (e) {
      return {'status': 'failure', 'error': e.toString()};
    }
  });

  // route to add user data
  app.post('addUser', (req, res) async {
    try {
      final body = await req.bodyAsJsonMap;
      final uid = body['uid'];
      // TODO: handle case when uid is already alloted
      if (uid == null) {
        throw Exception('uid not defined.');
      }
      final email = body['email'];
      if (email == null) {
        throw Exception('email not defined');
      }
      var password = body['password'];
      if (password == null) {
        throw Exception('password not defined.');
      }
      final data = (body['data'] ?? {}) as Map;
      // hash password using md5
      password = convertToMd5(password);
      await Api.instance
          .addUserData(uid: uid, email: email, password: password, data: data);
      return {
        'status': 'success',
        'data': {'uid': uid}
      };
    } on Exception catch (e) {
      return {'status': 'failure', 'error': e.toString()};
    }
  });

  app.post('loginWithEmailPassword', (req, res) async {
    try {
      final body = await req.bodyAsJsonMap;
      final email = body['email'];
      if (email == null) {
        throw Exception('email not defined');
      }
      var password = body['password'];
      if (password == null) {
        throw Exception('password not defined.');
      }
      // hash password using md5
      password = convertToMd5(password);
      final uid = await Api.instance
          .validateCredentials(email: email, password: password);
      if (uid == null) {
        throw Exception('email and password mismatch');
      }
      await Api.instance.updateSecurityTokenForUid(uid: uid);
      return {
        'status': 'success',
        'data': {
          'uid': uid,
        }
      };
    } on Exception catch (e) {
      return {'status': 'failure', 'error': e.toString()};
    }
  });

  await app.listen(3003);
}
