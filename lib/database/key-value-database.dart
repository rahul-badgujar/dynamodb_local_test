import 'dart:convert';
import 'package:http/http.dart' as http;

/// This is a demo database which stores uid and email of user
///
/// Note: please create table on ur local dynamo db before calling this api. (see end of this file for help)
class KeyValueDatabase {
  static final baseUrl = 'http://dynamodb.alpine.red:8000';

  /// header parameters which are common in all http requests
  static final commonHeaderParams = {
    'Content-Type': 'application/x-amz-json-1.0',
    'Accept-Encoding': 'identity',
    'Authorization':
        'AWS4-HMAC-SHA256 Credential=<Credential>, SignedHeaders=<Headers>, Signature=<Signature>',
  };

  /// Returns 'json data' for value associated with [key] in [tableName]
  /// * key here is map, it should contain a proper key schema which dynamodb requests for searching (see example below)
  ///   ```
  ///   {
  ///      'uid': {'N': key}
  ///   }
  ///   ```
  /// * If key is not present, empty json is returned.
  static Future<Map> getValue(
      {required String tableName, required Map key}) async {
    final bodyJson = {
      'TableName': tableName,
      'Key': key,
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
      return responseBodyJson;
    }
    throw Exception(
      'Failed to getValue($key), StatusCode: ${response.statusCode}',
    );
  }

  /// Adds [value] data for [key] in table [tableName]
  /// * If key not exists already, new data row is created
  /// * If key already exists, then data value is updated with new details provided with [value]
  /// * Value map should must have primary key value (see example below)
  static Future<void> putValue(
      {required String tableName, required Map key, required Map value}) async {
    final bodyJson = {
      'TableName': tableName,
      'Item': <dynamic, dynamic>{
        'value': {'M': value},
        ...key // adding primary key attribute for item
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
        'Failed to putValue($key, $value), StatusCode: ${response.statusCode}',
      );
    }
  }
}
