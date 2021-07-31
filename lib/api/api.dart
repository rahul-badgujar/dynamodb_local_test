import 'dart:convert';
import 'package:dynamodb_http_test/utils/response-parsing/response-parsing.dart';
import 'package:http/http.dart' as http;

/// This is a demo database which stores uid and email of user
///
/// Note: please create table on ur local dynamo db before calling this api. (see end of this file for help)
class Api {
  Api._();
  static final instance = Api._();

  /// default dtm to be alloted for security token.
  static final defaultLoginDtm = DateTime(1960);

  static final baseUrl = 'http://dynamodb.alpine.red:8000';

  /// header parameters which are common in all http requests
  static final commonHeaderParams = {
    'Content-Type': 'application/x-amz-json-1.0',
    'Accept-Encoding': 'identity',
    'Authorization':
        'AWS4-HMAC-SHA256 Credential=<Credential>, SignedHeaders=<Headers>, Signature=<Signature>',
  };

  /// Returns data of user having [uid] if exits, otherwise returns 'null'
  Future<Map?> getUserDataWithUid({required int uid}) async {
    final bodyJson = {
      'TableName': 'users',
      'Key': {
        'uid': {'N': uid.toString()}
      },
    };
    // define headers for http request
    final headers = <String, String>{
      'X-Amz-Target': 'DynamoDB_20120810.GetItem',
    };
    // add default header values
    headers.addAll(commonHeaderParams);

    final response = await http.post(
      Uri.parse('$baseUrl'),
      body: jsonEncode(bodyJson),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final responseBody = response.body;
      final responseBodyJson = jsonDecode(responseBody);
      final item = responseBodyJson['Item'];
      return item == null ? null : parseItemResponse(item);
    }
    throw Exception(
      'Failed to get user data [uid: $uid], StatusCode: ${response.statusCode}',
    );
  }

  /// Return the data of user having [email] if such user exits, otherwise returns 'null'
  Future<Map?> getUserDataWithEmail({required String email}) async {
    final bodyJson = {
      'TableName': 'users',
      'ExpressionAttributeValues': {
        ':email': {'S': email},
      },
      'FilterExpression': 'email = :email',
    };
    // define headers for http request
    final headers = <String, String>{
      'X-Amz-Target': 'DynamoDB_20120810.Scan',
    };
    // add default header values
    headers.addAll(commonHeaderParams);

    final response = await http.post(
      Uri.parse('$baseUrl'),
      body: jsonEncode(bodyJson),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final responseBody = response.body;
      final responseBodyJson = jsonDecode(responseBody);
      final items = (responseBodyJson['Items'] ?? []) as List;
      // if the response data list is empty, return null, otherwise return the user data parsed
      return items.isEmpty ? null : parseItemResponse(items.first);
    }
    throw Exception(
      'Failed to get user data [email: $email], StatusCode: ${response.statusCode}',
    );
  }

  /// Updates [data] for user having [uid]
  Future<void> addUserData(
      {required int uid,
      required String email,
      required String password,
      required Map data}) async {
    final bodyJson = {
      'TableName': 'users',
      'Item': <dynamic, dynamic>{
        'uid': {'N': uid.toString()},
        'email': {'S': email},
        'password': {'S': password},
        'securityToken': {'S': defaultLoginDtm.toString()},
        'json': {'M': data},
      },
    };
    // define headers for http request
    final headers = <String, String>{
      'X-Amz-Target': 'DynamoDB_20120810.PutItem',
    };
    // add default header values
    headers.addAll(commonHeaderParams);

    final response = await http.post(
      Uri.parse('$baseUrl'),
      body: jsonEncode(bodyJson),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update user data [uid: $uid], StatusCode: ${response.statusCode}',
      );
    }
  }

  /// Validates [email,password] credentials and returns [uid]
  ///
  /// In case of credential mismatch, returns null
  Future<int?> validateCredentials(
      {required String email, required String password}) async {
    final bodyJson = {
      'TableName': 'users',
      'ExpressionAttributeValues': {
        ':email': {'S': email},
        ':password': {'S': password},
      },
      'FilterExpression': 'email = :email and password = :password',
    };
    // define headers for http request
    final headers = <String, String>{
      'X-Amz-Target': 'DynamoDB_20120810.Scan',
    };
    // add default header values
    headers.addAll(commonHeaderParams);

    final response = await http.post(
      Uri.parse('$baseUrl'),
      body: jsonEncode(bodyJson),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final responseBody = response.body;
      final responseBodyJson = jsonDecode(responseBody);
      final items = (responseBodyJson['Items'] ?? []) as List;
      // if no user matches for given credentials, return null
      if (items.isEmpty) return null;
      final parsedItem = parseItemResponse(items.first);
      final uidString = parsedItem['uid'];
      final uid = int.tryParse(uidString);
      return uid;
    }
    throw Exception(
      'Failed to get user data [email: $email], StatusCode: ${response.statusCode}',
    );
  }

  /// Sets security [token] for user with [uid]
  Future<void> setSecurityTokenForUid(
      {required int uid, required String token}) async {
    final bodyJson = {
      'TableName': 'users',
      'Key': {
        'uid': {'N': uid.toString()}
      },
      'UpdateExpression': 'set securityToken = :token',
      'ExpressionAttributeValues': {
        ':token': {'S': token},
      },
    };
    // define headers for http request
    final headers = <String, String>{
      'X-Amz-Target': 'DynamoDB_20120810.UpdateItem',
    };
    // add default header values
    headers.addAll(commonHeaderParams);

    final response = await http.post(
      Uri.parse('$baseUrl'),
      body: jsonEncode(bodyJson),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update security token for given uid [uid: $uid], StatusCode: ${response.statusCode}',
      );
    }
  }

  /// Updates security token for user with [uid] with the current dtm
  Future<void> updateSecurityTokenForUid({required int uid}) async {
    final token = DateTime.now().toString();
    await setSecurityTokenForUid(uid: uid, token: token);
  }

  /// Reset security token for user with [uid], resets token to default [defaultLoginDtm]
  Future<void> resetSecurityTokenForUid({required int uid}) async {
    final token = defaultLoginDtm.toString();
    await setSecurityTokenForUid(uid: uid, token: token);
  }

  /// Returns 'true' if security token for user with [uid] is up and valid
  Future<bool> validateSecurityToken({required int uid}) async {
    final userData = await getUserDataWithUid(uid: uid);
    if (userData == null) {
      throw Exception('No user exists for given uid [uid:$uid]');
    }
    final currentSecurityToken = userData['securityToken'];
    // this is last login dtm token
    final tokenDtm = DateTime.tryParse(currentSecurityToken) ?? defaultLoginDtm;
    final currentDtm = DateTime.now();
    // substracting 30 days period from current dtm, this is the least dtm till which token will be valid
    final leastValidDtm = currentDtm.subtract(Duration(days: 30));
    // if token dtm is after the least valid dtm, then token is valid
    final isTokenValid = tokenDtm.isAfter(leastValidDtm);
    return isTokenValid;
  }
}
