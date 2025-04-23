import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';

class YouTubeService {
  // Replace with your actual API key
  static const String API_KEY = 'AIzaSyBNfhadhU14IJfzDkcaV_hPvWMmPKx4FSU';
  static const String BASE_URL = 'https://www.googleapis.com/youtube/v3';
  
  // Maximum retry attempts for API calls
  static const int MAX_RETRIES = 3;

  // Fetch trending videos with retry mechanism
  Future<List<VideoModel>> fetchTrendingVideos() async {
    return _retryApiCall(() async {
      final response = await http.get(
        Uri.parse('$BASE_URL/videos?part=snippet,statistics&chart=mostPopular&maxResults=15&key=$API_KEY'),
        headers: {'Accept': 'application/json'},
      );

      _validateResponse(response, 'Trending videos');
      
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> items = data['items'];
      
      if (items.isEmpty) {
        throw Exception('No trending videos found');
      }
      
      return _extractVideosFromItems(items);
    });
  }

  // Fetch videos by category
  Future<List<VideoModel>> fetchVideosByCategory(String categoryId) async {
    return _retryApiCall(() async {
      final response = await http.get(
        Uri.parse('$BASE_URL/videos?part=snippet,statistics&chart=mostPopular&videoCategoryId=$categoryId&maxResults=15&key=$API_KEY'),
        headers: {'Accept': 'application/json'},
      );

      _validateResponse(response, 'Videos by category $categoryId');
      
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> items = data['items'];
      
      return _extractVideosFromItems(items);
    });
  }
  Future<List<VideoModel>> fetchVideosFromPlaylists(String playlistId) async {
  return _retryApiCall(() async {
    final response = await http.get(
      Uri.parse('$BASE_URL/playlistItems?part=snippet&playlistId=$playlistId&maxResults=15&key=$API_KEY'),
      headers: {'Accept': 'application/json'},
    );

    _validateResponse(response, 'Videos from playlist $playlistId');

    Map<String, dynamic> data = json.decode(response.body);
    List<dynamic> items = data['items'];

    return items.map((item) {
      final snippet = item['snippet'];
      final videoId = snippet['resourceId']['videoId'];

      String thumbnailUrl = 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

      if (snippet['thumbnails'] != null) {
        if (snippet['thumbnails']['high'] != null) {
          thumbnailUrl = snippet['thumbnails']['high']['url'];
        } else if (snippet['thumbnails']['medium'] != null) {
          thumbnailUrl = snippet['thumbnails']['medium']['url'];
        }
      }

      return VideoModel(
        id: videoId,
        title: snippet['title'] ?? 'No title',
        thumbnailUrl: thumbnailUrl,
        channelTitle: snippet['channelTitle'] ?? 'Unknown channel',
        description: snippet['description'] ?? 'No description',
        viewCount: int.tryParse(snippet['statistics']?['viewCount'] ?? '0') ?? 0,
      );
    }).toList();
  });
}

Future<List<VideoModel>> fetchVideosFromPlaylist(String playlistId) async {
  return _retryApiCall(() async {
    print('Fetching videos from playlist: $playlistId');
    // Step 1: Fetch video IDs from the playlist
    final response = await http.get(
      Uri.parse('$BASE_URL/playlistItems?part=snippet&playlistId=$playlistId&maxResults=15&key=$API_KEY'),
      headers: {'Accept': 'application/json'},
    );

    _validateResponse(response, 'Videos from playlist $playlistId');

    Map<String, dynamic> data = json.decode(response.body);
    List<dynamic> items = data['items'];

    List<String> videoIds = items
        .map((item) => item['snippet']['resourceId']['videoId'] as String)
        .toList();

    if (videoIds.isEmpty) return [];

    // Step 2: Fetch video details (snippet + statistics)
    final detailsResponse = await http.get(
      Uri.parse('$BASE_URL/videos?part=snippet,statistics&id=${videoIds.join(',')}&key=$API_KEY'),
      headers: {'Accept': 'application/json'},
    );

    _validateResponse(detailsResponse, 'Video details for playlist $playlistId');

    Map<String, dynamic> detailsData = json.decode(detailsResponse.body);
    List<dynamic> detailedItems = detailsData['items'];

    return detailedItems.map((video) {
      final snippet = video['snippet'];
      final statistics = video['statistics'];
      final videoId = video['id'];

      String thumbnailUrl = 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

      if (snippet['thumbnails'] != null) {
        if (snippet['thumbnails']['high'] != null) {
          thumbnailUrl = snippet['thumbnails']['high']['url'];
        } else if (snippet['thumbnails']['medium'] != null) {
          thumbnailUrl = snippet['thumbnails']['medium']['url'];
        }
      }

      return VideoModel(
        id: videoId,
        title: snippet['title'] ?? 'No title',
        thumbnailUrl: thumbnailUrl,
        channelTitle: snippet['channelTitle'] ?? 'Unknown channel',
        description: snippet['description'] ?? 'No description',
        viewCount: int.tryParse(statistics['viewCount'] ?? '0') ?? 0,
      );
    }).toList();
  });
}

  // Search videos
  Future<List<VideoModel>> searchVideos(String query) async {
    return _retryApiCall(() async {
      final response = await http.get(
        Uri.parse('$BASE_URL/search?part=snippet&q=$query&type=video&maxResults=25&key=$API_KEY'),
        headers: {'Accept': 'application/json'},
      );

      _validateResponse(response, 'Search for $query');
      
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> items = data['items'];
      
      return items.map((item) {
        var snippet = item['snippet'];
        String thumbnailUrl = 'https://i.ytimg.com/vi/${item['id']['videoId']}/hqdefault.jpg';
        
        if (snippet['thumbnails'] != null) {
          if (snippet['thumbnails']['high'] != null) {
            thumbnailUrl = snippet['thumbnails']['high']['url'];
          } else if (snippet['thumbnails']['medium'] != null) {
            thumbnailUrl = snippet['thumbnails']['medium']['url'];
          } else if (snippet['thumbnails']['default'] != null) {
            thumbnailUrl = snippet['thumbnails']['default']['url'];
          }
        }
        
        return VideoModel(
          id: item['id']['videoId'],
          title: snippet['title'] ?? 'No title',
          thumbnailUrl: thumbnailUrl,
          channelTitle: snippet['channelTitle'] ?? 'Unknown channel',
          description: snippet['description'] ?? 'No description',
          viewCount: int.tryParse(snippet['statistics']?['viewCount'] ?? '0') ?? 0,
        );
      }).toList();
    });
  }

  // Get related videos
  Future<List<VideoModel>> getRelatedVideos(String videoId) async {
    return _retryApiCall(() async {
      final response = await http.get(
        Uri.parse('$BASE_URL/search?part=snippet&relatedToVideoId=$videoId&type=video&maxResults=10&key=$API_KEY'),
        headers: {'Accept': 'application/json'},
      );

      _validateResponse(response, 'Related videos for $videoId');
      
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> items = data['items'];
      
      return items.map((item) {
        var snippet = item['snippet'];
        String thumbnailUrl = 'https://i.ytimg.com/vi/${item['id']['videoId']}/hqdefault.jpg';
        
        if (snippet['thumbnails'] != null) {
          if (snippet['thumbnails']['high'] != null) {
            thumbnailUrl = snippet['thumbnails']['high']['url'];
          } else if (snippet['thumbnails']['medium'] != null) {
            thumbnailUrl = snippet['thumbnails']['medium']['url'];
          }
        }
        
        return VideoModel(
          id: item['id']['videoId'],
          title: snippet['title'] ?? 'No title',
          thumbnailUrl: thumbnailUrl,
          channelTitle: snippet['channelTitle'] ?? 'Unknown channel',
          description: snippet['description'] ?? 'No description',
          viewCount: int.tryParse(snippet['statistics']?['viewCount'] ?? '0') ?? 0,
        );
      }).toList();
    });
  }

  // Extract videos from API response items
  List<VideoModel> _extractVideosFromItems(List<dynamic> items) {
    return items.map((item) {
      var snippet = item['snippet'];
      String thumbnailUrl = 'https://i.ytimg.com/vi/${item['id']}/hqdefault.jpg';
      
      if (snippet['thumbnails'] != null) {
        if (snippet['thumbnails']['high'] != null) {
          thumbnailUrl = snippet['thumbnails']['high']['url'];
        } else if (snippet['thumbnails']['medium'] != null) {
          thumbnailUrl = snippet['thumbnails']['medium']['url'];
        }
      }
      
      return VideoModel(
        id: item['id'],
        title: snippet['title'] ?? 'No title',
        thumbnailUrl: thumbnailUrl,
        channelTitle: snippet['channelTitle'] ?? 'Unknown channel',
        description: snippet['description'] ?? 'No description',
        viewCount: int.tryParse(item['statistics']?['viewCount'] ?? '0') ?? 0,
      );
    }).toList();
  }

  // Validate API response
  void _validateResponse(http.Response response, String requestType) {
    if (response.statusCode != 200) {
      Map<String, dynamic> errorData = {};
      try {
        errorData = json.decode(response.body);
      } catch (e) {
        // If JSON parsing fails, use the raw body
      }

      String errorMessage = 'Failed to load $requestType (Status: ${response.statusCode})';
      
      if (errorData.containsKey('error') && errorData['error'].containsKey('message')) {
        errorMessage += ': ${errorData['error']['message']}';
      }
      
      throw Exception(errorMessage);
    }
  }

  // Generic retry mechanism for API calls
  Future<T> _retryApiCall<T>(Future<T> Function() apiCall) async {
    int attempt = 0;
    while (attempt < MAX_RETRIES) {
      try {
        return await apiCall();
      } catch (e) {
        attempt++;
        print('API call failed (Attempt $attempt/$MAX_RETRIES): $e');
        
        if (attempt >= MAX_RETRIES) {
          rethrow;
        }
        
        // Wait before retrying, with exponential backoff
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    // This should never be reached due to the rethrow above
    throw Exception('All retry attempts failed');
  }




}