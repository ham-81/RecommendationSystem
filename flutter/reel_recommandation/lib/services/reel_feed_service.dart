import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:reel_recommandation/models/reel_item.dart';

class ReelFeedService {
  ReelFeedService({
    http.Client? client,
    this.baseUrl = 'http://10.0.2.2:8000',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<List<ReelItem>> fetchFeed(int userId) async {
    final uri = Uri.parse('$baseUrl/feed/$userId?limit=20');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load feed: ${response.statusCode}');
    }

    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    final rawItems = (jsonBody['items'] as List<dynamic>? ?? []);

    return rawItems
        .map((item) => ReelItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendInteraction({
    required int userId,
    required int reelId,
    required String event,
  }) async {
    final uri = Uri.parse('$baseUrl/events/interaction');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'reel_id': reelId,
        'event': event,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to send interaction: ${response.statusCode}');
    }
  }
}
