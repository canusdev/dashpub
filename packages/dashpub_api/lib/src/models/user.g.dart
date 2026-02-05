// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  json['id'] as String,
  json['isAdmin'] as bool,
  json['email'] as String,
  json['name'] as String?,
  json['passwordHash'] as String,
  (json['teams'] as List<dynamic>).map((e) => e as String).toList(),
  json['token'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'isAdmin': instance.isAdmin,
  'email': instance.email,
  'name': instance.name,
  'passwordHash': instance.passwordHash,
  'teams': instance.teams,
  'token': instance.token,
};

Team _$TeamFromJson(Map<String, dynamic> json) => Team(
  json['id'] as String,
  json['name'] as String,
  (json['members'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$TeamToJson(Team instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'members': instance.members,
};

GlobalSettings _$GlobalSettingsFromJson(Map<String, dynamic> json) =>
    GlobalSettings(
      json['publicAccess'] as bool,
      json['defaultPrivate'] as bool,
      siteTitle: json['siteTitle'] as String?,
      logoUrl: json['logoUrl'] as String?,
      faviconUrl: json['faviconUrl'] as String?,
      registrationOpen: json['registrationOpen'] as bool? ?? true,
      allowedEmailDomains:
          (json['allowedEmailDomains'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$GlobalSettingsToJson(GlobalSettings instance) =>
    <String, dynamic>{
      'publicAccess': instance.publicAccess,
      'defaultPrivate': instance.defaultPrivate,
      'siteTitle': instance.siteTitle,
      'logoUrl': instance.logoUrl,
      'faviconUrl': instance.faviconUrl,
      'registrationOpen': instance.registrationOpen,
      'allowedEmailDomains': instance.allowedEmailDomains,
    };
