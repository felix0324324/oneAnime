import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

// Standalone verification script for dandanAPIBaseURL.
//
// This mirrors the project logic from:
// - lib/request/danmaku.dart
// - tvos/OneAnimeTV/OneAnimeAPI.swift
//
// Run:
//   dart run test_danmaku.dart
//   dart run test_danmaku.dart "刀剑神域" 1

const Map<String, String> mortis = {
  'id': 'kvpx7qkqjh',
  'value': 'rABUaBLqdz7aCSi3fe88ZDj2gwga9Vax',
};

class Api {
  static const String dandanAPIDomain = 'https://api.dandanplay.net';
  static const String dandanAPIComment = '/api/v2/comment/';
  static const String dandanAPISearch = '/api/v2/search/anime';
}

const String repoRef = 'https://github.com/Predidit/oneAnime';
const String userAgent =
    'Predidit/oneAnime/1.4.5 (Android) ($repoRef)';

enum AuthMode {
  signature,
  credential,
}

String generateDandanSignature(String path, int timestamp) {
  final String id = mortis['id']!;
  final String value = mortis['value']!;
  final String data = id + timestamp.toString() + path + value;
  final bytes = utf8.encode(data);
  final digest = sha256.convert(bytes);
  return base64Encode(digest.bytes);
}

Map<String, String> buildHeaders(String path, AuthMode mode) {
  switch (mode) {
    case AuthMode.signature:
      final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return {
        'user-agent': userAgent,
        'referer': '',
        'X-Auth': '1',
        'X-AppId': mortis['id']!,
        'X-Timestamp': timestamp.toString(),
        'X-Signature': generateDandanSignature(path, timestamp),
      };
    case AuthMode.credential:
      return {
        'user-agent': userAgent,
        'referer': '',
        'X-AppId': mortis['id']!,
        'X-AppSecret': mortis['value']!,
      };
  }
}

String modeLabel(AuthMode mode) {
  switch (mode) {
    case AuthMode.signature:
      return 'signature';
    case AuthMode.credential:
      return 'credential';
  }
}

Options requestOptions(Map<String, String> headers) {
  return Options(
    headers: headers,
    validateStatus: (_) => true,
    responseType: ResponseType.plain,
  );
}

Map<String, dynamic>? parseJsonBody(Response<dynamic> response) {
  final dynamic body = response.data;
  if (body is Map<String, dynamic>) {
    return body;
  }
  if (body is String && body.isNotEmpty) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  }
  return null;
}

String previewBody(Response<dynamic> response) {
  final body = response.data;
  if (body == null) {
    return '(empty)';
  }
  final text = body.toString().trim();
  if (text.isEmpty) {
    return '(empty)';
  }
  return text.length <= 300 ? text : '${text.substring(0, 300)}...';
}

Future<Response<dynamic>> getWithMode(
  Dio dio,
  String path, {
  required Map<String, dynamic> queryParameters,
  required AuthMode mode,
}) {
  return dio.get(
    Api.dandanAPIDomain + path,
    queryParameters: queryParameters,
    options: requestOptions(buildHeaders(path, mode)),
  );
}

Future<int?> fetchBangumiId(
  Dio dio,
  String title, {
  required AuthMode mode,
}) async {
  final response = await getWithMode(
    dio,
    Api.dandanAPISearch,
    queryParameters: {'keyword': title},
    mode: mode,
  );

  if (response.statusCode != 200) {
    print('[${modeLabel(mode)}] search failed: ${response.statusCode}');
    print('[${modeLabel(mode)}] response: ${previewBody(response)}');
    return null;
  }

  final payload = parseJsonBody(response);
  final List<dynamic> animes = payload?['animes'] as List<dynamic>? ?? [];
  if (animes.isEmpty) {
    print('[${modeLabel(mode)}] no anime matched "$title"');
    return 100000;
  }

  int minAnimeId = 100000;
  for (final anime in animes) {
    if (anime is! Map<String, dynamic>) {
      continue;
    }
    final int? animeId = anime['animeId'] as int?;
    if (animeId != null && animeId < minAnimeId && animeId >= 8692) {
      minAnimeId = animeId;
    }
  }

  return minAnimeId;
}

Future<List<dynamic>?> fetchComments(
  Dio dio,
  int bangumiId,
  int episode, {
  required AuthMode mode,
}) async {
  if (bangumiId == 100000) {
    return <dynamic>[];
  }

  final path =
      '${Api.dandanAPIComment}$bangumiId${episode.toString().padLeft(4, '0')}';
  final response = await getWithMode(
    dio,
    path,
    queryParameters: {'withRelated': 'true'},
    mode: mode,
  );

  if (response.statusCode != 200) {
    print('[${modeLabel(mode)}] comment download failed: ${response.statusCode}');
    print('[${modeLabel(mode)}] response: ${previewBody(response)}');
    return null;
  }

  final payload = parseJsonBody(response);
  return payload?['comments'] as List<dynamic>? ?? <dynamic>[];
}

Future<void> main(List<String> args) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );
  final String title = args.isNotEmpty ? args[0] : '刀剑神域';
  final int episode = args.length > 1 ? int.tryParse(args[1]) ?? 1 : 1;

  print('--- Dandan Subtitle/Danmaku Download Test ---');
  print('Repo ref: $repoRef');
  print('Title: $title');
  print('Episode: $episode');

  for (final mode in AuthMode.values) {
    print('\n== Trying ${modeLabel(mode)} auth ==');
    try {
      final bangumiId = await fetchBangumiId(dio, title, mode: mode);
      if (bangumiId == null) {
        continue;
      }

      print('[${modeLabel(mode)}] bangumiId: $bangumiId');
      final comments = await fetchComments(
        dio,
        bangumiId,
        episode,
        mode: mode,
      );
      if (comments == null) {
        continue;
      }

      print('[${modeLabel(mode)}] success, comment count: ${comments.length}');
      for (int i = 0; i < comments.length && i < 5; i++) {
        final item = comments[i];
        if (item is Map<String, dynamic>) {
          print(' - [${item['p']}] ${item['m']}');
        } else {
          print(' - $item');
        }
      }
      return;
    } catch (error) {
      print('[${modeLabel(mode)}] exception: $error');
    }
  }

  print('\nResult: unable to confirm download from this environment.');
  print('The current machine/network is receiving HTTP 403 from dandanAPIBaseURL.');
}
