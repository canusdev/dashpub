import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final bool isAdmin;
  final String email;
  final String? name;
  final String passwordHash;
  final List<String> teams;
  final String? token;

  User(
    this.id,
    this.isAdmin,
    this.email,
    this.name,
    this.passwordHash,
    this.teams,
    this.token,
  );

  factory User.fromJson(Map<String, dynamic> map) => _$UserFromJson(map);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.isAdmin == isAdmin &&
        other.email == email &&
        other.name == name &&
        other.passwordHash == passwordHash &&
        other.token == token;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        isAdmin.hashCode ^
        email.hashCode ^
        name.hashCode ^
        passwordHash.hashCode ^
        token.hashCode;
  }
}

@JsonSerializable()
class Team {
  final String id;
  final String name;
  final List<String> members;

  Team(this.id, this.name, this.members);

  factory Team.fromJson(Map<String, dynamic> map) => _$TeamFromJson(map);
  Map<String, dynamic> toJson() => _$TeamToJson(this);
}

@JsonSerializable()
class GlobalSettings {
  final bool publicAccess;
  final bool defaultPrivate;
  final String? siteTitle;
  final String? logoUrl;
  final String? faviconUrl;
  final bool registrationOpen;
  final List<String> allowedEmailDomains;

  GlobalSettings(
    this.publicAccess,
    this.defaultPrivate, {
    this.siteTitle,
    this.logoUrl,
    this.faviconUrl,
    @JsonKey(defaultValue: true) this.registrationOpen = true,
    @JsonKey(defaultValue: []) this.allowedEmailDomains = const [],
  });

  factory GlobalSettings.fromJson(Map<String, dynamic> map) =>
      _$GlobalSettingsFromJson(map);
  Map<String, dynamic> toJson() => _$GlobalSettingsToJson(this);
}
