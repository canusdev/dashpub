import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dashpub_api.dart'; // For DTOs

class DashpubApiClient {
  final String baseUrl;
  final http.Client _client;
  String? _token;

  DashpubApiClient(this.baseUrl, {http.Client? client, String? token})
    : _client = client ?? http.Client(),
      _token = token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<AuthResponse> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
    }
  }

  Future<AuthResponse> register(
    String email,
    String password,
    String? name,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );
    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Registration failed',
      );
    }
  }

  Future<User> getMe() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Unauthorized');
    }
  }

  Future<User> updateMe({String? name, String? password}) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _headers,
      body: jsonEncode({
        if (name != null) 'name': name,
        if (password != null) 'password': password,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to update profile',
      );
    }
  }

  Future<String> generateToken() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/token'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['token'] as String;
    } else {
      throw Exception('Failed to generate token');
    }
  }

  Future<ListApi> getPackages({
    int size = 10,
    int page = 0,
    String sort = 'download',
    String? q,
  }) async {
    final uri = Uri.parse('$baseUrl/webapi/packages').replace(
      queryParameters: {
        'size': size.toString(),
        'page': page.toString(),
        'sort': sort,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );

    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ListApi.fromJson(json['data']);
    } else {
      throw Exception('Failed to load packages');
    }
  }

  Future<WebapiDetailView> getPackageDetail(
    String name, {
    String version = 'latest',
  }) async {
    final uri = Uri.parse('$baseUrl/webapi/package/$name/$version');
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['error'] != null) {
        throw Exception(json['error']);
      }
      return WebapiDetailView.fromJson(json['data']);
    } else {
      throw Exception('Failed to load package detail');
    }
  }

  Future<GlobalSettings> getSettings() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/settings'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return GlobalSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load settings');
    }
  }

  Future<void> updateSettings(GlobalSettings settings) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/settings'),
      headers: _headers,
      body: jsonEncode(settings.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update settings');
    }
  }

  Future<bool> isInitialized() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/auth/initialized'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['initialized'] as bool;
    } else {
      throw Exception('Failed to check system status');
    }
  }

  Future<List<Team>> getTeams() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/teams'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['teams'] as List<dynamic>)
          .map((e) => Team.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load teams');
    }
  }

  Future<Team> createTeam(String name) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/teams'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      return Team.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to create team',
      );
    }
  }

  Future<List<User>> adminGetUsers() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['users'] as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to load users',
      );
    }
  }

  Future<List<Team>> adminGetTeams() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/admin/teams'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['teams'] as List<dynamic>)
          .map((e) => Team.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to load teams',
      );
    }
  }

  // CLI specific: publish
  Future<void> publish(List<int> bytes) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/packages/versions/new-upload'),
    );

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: 'package.tar.gz'),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ?? 'Publish failed';
      throw Exception(error);
    }
  }

  // Uploader Management
  Future<void> addUploader(String packageName, String email) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/packages/$packageName/uploaders'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to add uploader',
      );
    }
  }

  Future<void> removeUploader(String packageName, String email) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/packages/$packageName/uploaders/$email'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to remove uploader',
      );
    }
  }

  // Admin User Management
  Future<User> adminCreateUser({
    required String email,
    required String password,
    String? name,
    bool isAdmin = false,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'isAdmin': isAdmin,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to create user',
      );
    }
  }

  Future<User> adminUpdateUser(String userId, {bool? isAdmin}) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/admin/users/$userId'),
      headers: _headers,
      body: jsonEncode({if (isAdmin != null) 'isAdmin': isAdmin}),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to update user',
      );
    }
  }

  // Team Management
  Future<Team> getTeam(String teamId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/teams/$teamId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return Team.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to load team',
      );
    }
  }

  Future<Team> addTeamMember(String teamId, String email) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/teams/$teamId/members/$email'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return Team.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to add member',
      );
    }
  }

  Future<Team> removeTeamMember(String teamId, String userId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/teams/$teamId/members/$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return Team.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to remove member',
      );
    }
  }

  void close() {
    _client.close();
  }
}
