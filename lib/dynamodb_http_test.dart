import 'package:dynamodb_http_test/user-database.dart';

Future<void> run() async {
  /* // example of put value
  await UserDatabase.instance.putValue('1', 'rahul@tenfins.com');
  print('New Value added successfully'); */
  // example of get value
  final value = await UserDatabase.instance.getValue('3');
  print('Result of GetValue: $value');
}
