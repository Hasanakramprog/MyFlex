import 'dart:convert';
import 'package:my_app/history_service.dart';
import 'package:my_app/models/history_model.dart';
import 'package:my_app/screens/drawer_screen.dart';
import 'package:my_app/screens/history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../models/video_model.dart';
import '../models/playlist_model.dart';
import '../youtube_service.dart';
import 'video_player_screen.dart';
import 'coming_soon_screen.dart';
import 'downloads_screen.dart';
import 'more_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final YouTubeService _youtubeService = YouTubeService();
  final HistoryService _historyService = HistoryService();
  Future<List<VideoModel>>? _trendingVideosFuture;
  Future<List<VideoModel>>? _musicVideosFuture;
  Future<List<VideoModel>>? _comedyVideosFuture;
  Future<List<VideoModel>>? _gamingVideosFuture;
  List<Playlist> _localPlaylists = [];
  Map<String, Future<List<VideoModel>>> _playlistVideoFutures = {};

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _selectedIndex = 0;

  // Fallback featured video in case API fails
  final VideoModel _fallbackVideo = VideoModel(
    id: 'dQw4w9WgXcQ',
    title: 'Rick Astley - Never Gonna Give You Up',
    thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
    channelTitle: 'Rick Astley',
    description: 'The classic hit song from Rick Astley',
    viewCount: 100,
  );

  @override
  void initState() {
    super.initState();

    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load trending videos first to ensure we have something for the featured section
      // final trendingVideoss = await _youtubeService.fetchTrendingVideos();
      // final trendingVideos = await _youtubeService.searchVideos("A DREAM NIGHT UNDER THE MUNICH SKY ");
      final trendingVideos = await _youtubeService.fetchVideosFromPlaylist(
        "PLu2SKVHcRFLobuTmDMG9z5cZNzrogLbn5",
      );

      if (mounted) {
        setState(() {
          _trendingVideosFuture = Future.value(trendingVideos);
          _isLoading = false;

          // Only load other categories if we successfully loaded trending
          _loadLocalPlaylists();
          // _loadOtherCategories();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load videos: ${e.toString()}';
          _isLoading = false;

          // Set fallback data for trending
          _trendingVideosFuture = Future.value([_fallbackVideo]);
        });
        print('Error loading trending videos: $e');
      }
    }
  }

  Future<List<Playlist>> loadPlaylistsFromJson() async {
    final String jsonString = await rootBundle.loadString(
      'assets/saved_playlists.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((e) => Playlist.fromJson(e)).toList();
  }

  Future<void> _loadLocalPlaylists() async {
    try {
      final playlists = await loadPlaylistsFromJson(); // From your assets
      final Map<String, Future<List<VideoModel>>> futuresMap = {};

      for (var playlist in playlists) {
        futuresMap[playlist.title] = _youtubeService.fetchVideosFromPlaylist(
          playlist.id,
        );
      }

      if (mounted) {
        setState(() {
          _localPlaylists = playlists;
          _playlistVideoFutures = futuresMap;
        });
      }
    } catch (e) {
      print('Error loading playlists: $e');
    }
  }

  Future<void> _loadOtherCategories() async {
    try {
      final musicVideos = _youtubeService.fetchVideosByCategory('10');
      final comedyVideos = _youtubeService.fetchVideosByCategory('23');
      final gamingVideos = _youtubeService.fetchVideosByCategory('20');

      if (mounted) {
        setState(() {
          _musicVideosFuture = musicVideos;
          _comedyVideosFuture = comedyVideos;
          _gamingVideosFuture = gamingVideos;
        });
      }
    } catch (e) {
      print('Error loading category videos: $e');
      // We don't set hasError here since we already have trending videos
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(),

      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        elevation: 0,
        title: AnimatedTextKit(
          animatedTexts: [
            ColorizeAnimatedText(
              'MYFLIX',
              textStyle: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Monospace',
              ),
              colors: [
                Colors.red,
                Colors.white,
                Colors.redAccent,
                Colors.black,
              ],
              speed: Duration(milliseconds: 500),
            ),
          ],
          repeatForever: true,
          isRepeatingAnimation: true,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              // Profile functionality would go here
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? _buildLoadingIndicator()
              : _hasError
              ? _buildErrorView()
              : RefreshIndicator(
                onRefresh: () async {
                  await _loadVideos();
                },
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Featured video - large banner
                      _buildFeaturedVideo(),
                      SizedBox(height: 20),

                      // // Trending section
                      // _buildVideoSectionFromFuture('Trending Now', _trendingVideosFuture),

                      // // Music section
                      // _buildVideoSectionFromFuture('Music', _musicVideosFuture),

                      // // Comedy section
                      // _buildVideoSectionFromFuture('Comedy', _comedyVideosFuture),

                      // // Gaming section
                      // _buildVideoSectionFromFuture('Gaming', _gamingVideosFuture),
                      // _buildVideoSectionFromFuture('Local Playlists', _playlistVideoFutures.values.first),
                      ..._playlistVideoFutures.entries.map((entry) {
                        return _buildVideoSectionFromFuture(
                          entry.key,
                          entry.value,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            // Home tapped - do nothing or refresh home
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          } else if (index == 1) {
            // Navigate to Coming Soon screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => HistoryScreen(
                      historyService: _historyService,
                    ), // <- create this screen
              ),
            );
          } else if (index == 2) {
            // Navigate to Downloads screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DownloadsScreen(), // <- create this screen
              ),
            );
          } else if (index == 3) {
            // Navigate to More screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MoreScreen(), // <- create this screen
              ),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Loading amazing content for you...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 60),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: _loadVideos,
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }


  Widget _buildFeaturedVideo() {
    return FutureBuilder<HistoryItem?>(
      future: _historyService.getLastWatchedVideo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 250,
            child: Center(child: CircularProgressIndicator(color: Colors.red)),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          return _buildFeaturedVideoWithProgress(
            snapshot.data!,
          ); // 👈 Last watched video
        } else {
          // fallback to first trending
          return FutureBuilder<List<VideoModel>>(
            future: _trendingVideosFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 250,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
                );
              } else if (!snap.hasData || snap.data!.isEmpty) {
                return _buildFeaturedVideoItem(_fallbackVideo);
              } else {
                return _buildFeaturedVideoItem(snap.data!.first);
              }
            },
          );
        }
      },
    );
  }

  Widget _buildFeaturedVideoWithProgress(HistoryItem historyItem) {
    return Stack(
      children: [
        _buildFeaturedVideoItem(
          VideoModel(
            id: historyItem.videoId,
            title: historyItem.title,
            thumbnailUrl: historyItem.thumbnailUrl,
            viewCount: historyItem.viewCount,
            channelTitle: historyItem.playlistTitle ?? 'Unknown Playlist',
            description: historyItem.title,
            // Add other required VideoModel properties
          ),
        ),

        // Progress bar at the bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(
            value: historyItem.watchProgress / 100,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            minHeight: 4,
          ),
        ),

        // "Continue Watching" badge
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Continue Watching',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Progress percentage text
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${historyItem.watchProgress.round()}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedVideoItem(VideoModel video) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => VideoPlayerScreen(
                  videoId: video.id,
                  title: video.title,
                  playlistTitle: video.channelTitle ?? 'Unknown Playlist',
                  viewCount: video.viewCount.toString(),
                  historyService: _historyService,
                ),
          ),
        );
      },
      child: Container(
        height: 250,
        width: double.infinity,
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: video.thumbnailUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(height: 8),
                          Text(
                            'Image could not be loaded',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => VideoPlayerScreen(
                                      videoId: video.id,
                                      title: video.title,
                                      playlistTitle: video.title,
                                      viewCount: video.viewCount.toString(),
                                      historyService: _historyService,
                                    ),
                              ),
                            );
                          },
                          icon: Icon(Icons.play_arrow),
                          label: Text('Play'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                        ),
                        SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Add to My List functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to My List'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(Icons.add),
                          label: Text('My List'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSectionFromFuture(
    String title,
    Future<List<VideoModel>>? videosFuture,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: 180,
          child: FutureBuilder<List<VideoModel>>(
            future: videosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingShimmer();
              } else if (snapshot.hasError) {
                return _buildErrorRow(
                  'Error loading videos. Pull down to refresh.',
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                // If this is the trending section, use fallback
                if (title == 'Trending Now') {
                  return _buildVideoRow([_fallbackVideo], title);
                }
                return _buildErrorRow('No videos available for this category');
              }

              List<VideoModel> videos = snapshot.data!;
              return _buildVideoRow(videos, title);
            },
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildVideoRow(List<VideoModel> videos, String playlist_title) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            saveLastWatchedVideo(videos[index]);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => VideoPlayerScreen(
                      videoId: videos[index].id,
                      title: videos[index].title,
                      playlistTitle: playlist_title,
                      viewCount: videos[index].viewCount.toString(),
                      historyService: _historyService,
                    ),
              ),
            );
          },
          child: Container(
            width: 270,
            margin: EdgeInsets.only(left: 16.0, bottom: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.grey[900],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: videos[index].thumbnailUrl,
                    height: 130,
                    width: 270,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.red),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey[800],
                          height: 130,
                          child: Center(child: Icon(Icons.error)),
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    videos[index].title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 270,
          margin: EdgeInsets.only(left: 16.0, bottom: 16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.grey[900],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 130,
                width: 270,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 14,
                  width: 200,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorRow(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          message,
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Simple search dialog
  void _showSearchDialog() {
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Search Videos', style: TextStyle(color: Colors.white)),
          content: TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter search term...',
              hintStyle: TextStyle(color: Colors.grey),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
            onChanged: (value) {
              searchQuery = value;
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Search', style: TextStyle(color: Colors.red)),
              onPressed: () {
                if (searchQuery.isNotEmpty) {
                  Navigator.of(context).pop();
                  _performSearch(searchQuery);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _performSearch(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  Future<void> saveLastWatchedVideo(VideoModel video) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('lastWatchedVideo', json.encode(video.toJson()));
  }

  Future<VideoModel?> _loadLastWatchedVideo() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('lastWatchedVideo');

    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return VideoModel.fromJson(jsonMap);
    }

    return null; // nothing watched yet
  }
}
