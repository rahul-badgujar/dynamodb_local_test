import '../database/key-value-database.dart';

class Api {
  Api._();
  static final instance = Api._();

  Future<Map> getUserData({required int uid}) async {
    final userData = await KeyValueDatabase.getValue(
      tableName: 'users',
      key: {
        'uid': {'N': '$uid'}
      },
    );
    return userData;
  }

  Future<void> updateUserData({required int uid, required Map data}) async {
    await KeyValueDatabase.putValue(
      tableName: 'users',
      key: {
        'uid': {'N': '$uid'}
      },
      value: data,
    );
  }
}
