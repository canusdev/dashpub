import 'package:mongo_dart/mongo_dart.dart';
import 'package:dashpub_api/dashpub_api.dart';
import '../lib/src/data/mongo_store.dart';

void main() async {
  final db = Db('mongodb://localhost:27017/dashpub');
  await db.open();

  final store = MongoStore(db);

  // Simulate m@m.com user
  final user = User(
    'm@m.com', // id
    false, // isAdmin
    'm@m.com', // email
    'deneme', // name
    'hash', // password
    [], // teams
    null, // token
  );

  print('Querying for user: ${user.email} (isAdmin: ${user.isAdmin})');

  try {
    final result = await store.queryPackages(
      size: 10,
      page: 0,
      sort: 'download',
      user: user,
    );

    print('Found: ${result.count}');
    for (var p in result.packages) {
      print(' - ${p.name} (private: ${p.private})');
    }
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }

  await db.close();
}
