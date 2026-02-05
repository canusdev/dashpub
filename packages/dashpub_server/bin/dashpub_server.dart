import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dashpub/dashpub.dart';
import 'package:minio/minio.dart';

void main(List<String> args) async {
  final mongoUrl =
      Platform.environment['DASHPUB_MONGO_URL'] ??
      'mongodb://localhost:27017/dashpub';
  final database = Db(mongoUrl);

  // Retry logic for MongoDB connection
  var connected = false;
  var retries = 0;
  const maxRetries = 10;

  while (!connected && retries < maxRetries) {
    try {
      print('Connecting to MongoDB at $mongoUrl (attempt ${retries + 1})...');
      await database.open();
      connected = true;
      print('Successfully connected to MongoDB.');
    } catch (e) {
      retries++;
      if (retries >= maxRetries) {
        print(
          'Failed to connect to MongoDB after $maxRetries attempts. Exiting.',
        );
        rethrow;
      }
      print('Connection failed: $e. Retrying in 5 seconds...');
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  final staticAssetsPath = Platform.environment['DASHPUB_STATIC_ASSETS_PATH'];
  final metaStore = MongoStore(database);

  PackageStore packageStore;
  final storageDriver =
      Platform.environment['DASHPUB_STORAGE_DRIVER'] ?? 'file';

  if (storageDriver == 's3') {
    final endpoint = Platform.environment['DASHPUB_S3_ENDPOINT'];
    final bucket = Platform.environment['DASHPUB_S3_BUCKET'];
    final accessKey = Platform.environment['DASHPUB_S3_ACCESS_KEY'];
    final secretKey = Platform.environment['DASHPUB_S3_SECRET_KEY'];
    final region = Platform.environment['DASHPUB_S3_REGION'];

    if (endpoint == null ||
        bucket == null ||
        accessKey == null ||
        secretKey == null) {
      print(
        '[ERROR] S3 storage driver requires DASHPUB_S3_ENDPOINT, DASHPUB_S3_BUCKET, DASHPUB_S3_ACCESS_KEY, and DASHPUB_S3_SECRET_KEY',
      );
      exit(1);
    }

    print('Using S3 Storage with endpoint $endpoint and bucket $bucket');
    final minio = Minio(
      endPoint: endpoint,
      accessKey: accessKey,
      secretKey: secretKey,
      region: region, // Optional
    );
    packageStore = S3Store(minio, bucket);
  } else {
    final baseDir = Platform.environment['DASHPUB_STORAGE_PATH'] ?? './data';
    print('Using File Storage at $baseDir');
    packageStore = FileStore(baseDir);
  }

  final app = DashpubApp(
    metaStore: metaStore,
    packageStore: packageStore,
    staticAssetsPath: staticAssetsPath,
  );

  final port = int.tryParse(Platform.environment['PORT'] ?? '4000') ?? 4000;
  final server = await app.serve('0.0.0.0', port);
  print(
    'Dashpub Renew serving at http://${server.address.address}:${server.port}',
  );
}
