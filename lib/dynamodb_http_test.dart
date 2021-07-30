import 'package:alfred/alfred.dart';

Future<void> run() async {
  final app = Alfred();
  app.all('example', (req, res) => 'Welcome to DynamoDB Test');
  await app.listen(3003);
}
