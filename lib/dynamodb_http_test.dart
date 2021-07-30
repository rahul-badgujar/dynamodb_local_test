import 'package:alfred/alfred.dart';
import 'package:dynamodb_http_test/database/key-value-database.dart';

Future<void> run() async {
  final app = Alfred();
  app.all('example', (req, res) => 'Welcome to DynamoDB Test');
  // route to get details of user
  app.get('user/:uid', (req, res) async {
    try {
      final uid = req.params['uid'];
      if (uid == null) {
        throw Exception('uid not defined.');
      }
      final userData = await KeyValueDatabase.getValue(
        tableName: 'users',
        key: {
          'uid': {'N': '$uid'}
        },
      );
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
      await KeyValueDatabase.putValue(
          tableName: 'users',
          key: {
            'uid': {'N': '$uid'}
          },
          value: data);
      return {
        'status': 'success',
        'data': {'uid': uid}
      };
    } on Exception catch (e) {
      return {'status': 'failure', 'error': e.toString()};
    }
  });
  await app.listen(3003);
}
