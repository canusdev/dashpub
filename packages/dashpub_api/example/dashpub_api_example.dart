import 'package:dashpub_api/dashpub_api.dart';

void main() async {
  // 1. Create a client instance
  final client = DashpubApiClient('https://dashpub.yourdomain.com');

  // 2. Check system initialization status
  final isInitialized = await client.isInitialized();
  print('System initialized: $isInitialized');

  if (!isInitialized) {
    print('System not initialized. Please create an admin account.');
    return;
  }

  try {
    // 3. Authenticate
    final authResponse = await client.login('admin@example.com', 'password');
    print('Logged in as: ${authResponse.user.email}');

    // 4. Set the token for future requests
    client.setToken(authResponse.token);

    // 5. Fetch packages
    final packages = await client.getPackages(size: 5);
    print('Found ${packages.count} packages:');
    for (var pkg in packages.packages) {
      print(' - ${pkg.name} (v${pkg.latest})');
    }

    // 6. Get package details
    if (packages.packages.isNotEmpty) {
      final firstPkg = packages.packages.first;
      final details = await client.getPackageDetail(firstPkg.name);
      print('Details for ${firstPkg.name}: ${details.description}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    // 7. Close the client
    client.close();
  }
}
