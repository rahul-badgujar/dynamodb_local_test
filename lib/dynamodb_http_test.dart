import 'package:alfred/alfred.dart';
import 'package:dynamodb_http_test/api/api.dart';

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
      final userData = await Api.instance.getUserData(uid: uid);
      return {
        'status': 'success',
        'data': userData,
      };
    } on Exception catch (e) {
      return {'status': 'failure', 'error': e.toString()};
    }
  });

  // route to add user data
  app.post('updateUser', (req, res) async {
    try {
      final body = await req.bodyAsJsonMap;
      final uid = body['uid'];
      if (uid == null) {
        throw Exception('uid not defined.');
      }
      final data = (body['data'] ?? {}) as Map;
      await Api.instance.updateUserData(uid: uid, data: data);
      return {
        'status': 'success',
        'data': {'uid': uid}
      };
    } on Exception catch (e) {
      return {'status': 'failure', 'error': e.toString()};
    }
  });

  // route for email-password login

  await app.listen(3003);
}
