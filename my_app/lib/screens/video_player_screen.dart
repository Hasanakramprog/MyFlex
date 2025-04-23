import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/history_service.dart';
import 'package:my_app/models/history_model.dart';
import 'package:my_app/models/playlist_model.dart';
import 'package:my_app/screens/coming_soon_screen.dart';
import 'package:my_app/screens/downloads_screen.dart';
import 'package:my_app/screens/history_screen.dart';
import 'package:my_app/screens/home_screen.dart';
import 'package:my_app/screens/more_screen.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';
import '../youtube_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String playlistTitle;
  final String viewCount;
  final HistoryService historyService;

  const VideoPlayerScreen({
    Key? key,
    required this.videoId,
    required this.title,
    required this.playlistTitle,
    required this.viewCount,
    required this.historyService,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final HistoryService _historyService = HistoryService();
  int _selectedIndex = 0;
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;
  final YouTubeService _youtubeService = YouTubeService();
  bool _showEpisodes = false;
  String _playlistId = '';
  bool _isAddedToHistory = false;
  int _totalDuration = 0;
  int _currentPosition = 0;
  Timer? _progressTracker;
  DateTime? _startWatchTime;
  bool _hasLoadedPlaylist = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    loadPlaylistForTitle(widget.playlistTitle);
    _startWatchTime = DateTime.now();

    // Check if we should resume from a previous position
    _checkForResumePosition();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        useHybridComposition: true,
        forceHD: false,
      ),
    );

    // Set up periodic tracking and listeners
    _controller.addListener(() {
      final newPosition = _controller.value.position.inSeconds;
      final newDuration = _controller.value.metaData.duration.inSeconds;
      _currentPosition = newPosition;
      _totalDuration = newDuration;
      // setState(() {
      //   _currentPosition = newPosition;
      //   _totalDuration = newDuration;
      // });

      // Calculate watch progress
      double progress = 0.0;
      if (_totalDuration > 0) {
        progress = (_currentPosition / _totalDuration) * 100;
      }

      // Add to history after 10 seconds of watching
      if (!_isAddedToHistory && _currentPosition >= 10) {
        _addToHistory(progress: progress);
        _isAddedToHistory = true;
      }

      // Update history periodically for progress tracking
      if (_isAddedToHistory && newPosition % 30 == 0 && newPosition > 0) {
        // Update every 30 seconds
        _updateHistoryProgress(progress: progress);
      }
    });

    // Start periodic progress tracking
    _progressTracker = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isAddedToHistory && _totalDuration > 0) {
        double progress = (_currentPosition / _totalDuration) * 100;
        _updateHistoryProgress(progress: progress);
      }
    });
  }

  @override
  void dispose() {
    // Final update to watch history before disposing
    if (_isAddedToHistory && _totalDuration > 0) {
      double progress = (_currentPosition / _totalDuration) * 100;
      _updateHistoryProgress(progress: progress, isFinal: true);
    }

    _progressTracker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkForResumePosition() async {
    try {
      // Get history for this video
      final historyItems = await widget.historyService.getHistory();
      final thisVideoHistory = historyItems.firstWhere(
        (item) => item.videoId == widget.videoId,
        orElse:
            () => HistoryItem(
              videoId: widget.videoId,
              title: widget.title,
              thumbnailUrl:
                  'https://img.youtube.com/vi/${widget.videoId}/mqdefault.jpg',
              watchedAt: DateTime.now(),
              viewCount: int.tryParse(widget.viewCount) ?? 0,
              lastPositionInSeconds: 0,
            ),
      );

      // If we have a saved position and it's less than 98% of the video
      if (thisVideoHistory.lastPositionInSeconds > 0 &&
          thisVideoHistory.watchProgress < 98) {
        // Ask user if they want to resume
        _showResumeDialog(thisVideoHistory.lastPositionInSeconds);
      }
    } catch (e) {
      print("Error checking resume position: $e");
    }
  }

  void _showResumeDialog(int resumePosition) {
    // Don't show for very short positions (less than 30 seconds)
    if (resumePosition < 30) return;

    String formattedTime = _formatDuration(Duration(seconds: resumePosition));

    // Wait for player to initialize before showing dialog
    Future.delayed(Duration(seconds: 1), () {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Resume Watching?',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Would you like to continue watching from $formattedTime?',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Start Over',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Resume', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    _controller.seekTo(Duration(seconds: resumePosition));
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
        onReady: () {
          // Perform any actions on player ready
        },
        onEnded: (data) {
          setState(() {
            _isFullScreen = false;
          });
        },
      ),
      builder: (context, player) {
        debugPrint('Building related videos list - isPlaying:');
        return Scaffold(
          backgroundColor: Colors.black,
          appBar:
              _isFullScreen
                  ? null
                  : AppBar(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    title: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          body: Column(
            children: [
              player,
              if (!_isFullScreen)
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.remove_red_eye,
                                color: Colors.grey,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${formatViewCount(int.tryParse(widget.viewCount) ?? 0)}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(Icons.thumb_up, 'Like'),
                              _buildActionButton(Icons.share, 'Share'),
                              _buildActionButton(Icons.download, 'Download'),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showEpisodes = !_showEpisodes;
                                  });
                                },
                                icon: Icon(
                                  _showEpisodes
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.red,
                                ),
                                label: Text(
                                  'Episodes',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                          Divider(color: Colors.grey[800]),
                          SizedBox(height: 16),
                          Text(
                            'More Like This',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          if (_showEpisodes)
                            buildRelatedVideosByList(context, _playlistId),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                _isFullScreen = !_isFullScreen;
              });
              _controller.toggleFullScreenMode();
            },
            child: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
            ),
            backgroundColor: Colors.red,
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
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.download),
                label: 'Downloads',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }

  Widget buildRelatedVideosByList(BuildContext context, String listId) {
    return FutureBuilder<List<VideoModel>>(
      future: _youtubeService.fetchVideosFromPlaylist(listId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.red));
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No related videos found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final relatedVideos = snapshot.data!;

        return SizedBox(
          height: 300,
          child: GridView.builder(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: 8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: relatedVideos.length,
            itemBuilder: (context, index) {
              final video = relatedVideos[index];

              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => VideoPlayerScreen(
                            videoId: video.id,
                            title: video.title,
                            playlistTitle: widget.playlistTitle,
                            viewCount: video.viewCount.toString(),
                            historyService: widget.historyService,
                          ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: video.thumbnailUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder:
                                (context, url) => Container(
                                  color: Colors.grey[800],
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) =>
                                    Icon(Icons.error, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<String?> getPlaylistIdByTitle(String title) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/saved_playlists.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      for (var item in jsonData) {
        final playlist = Playlist.fromJson(item);
        if (playlist.title.toLowerCase() == title.toLowerCase()) {
          return playlist.id;
        }
      }

      return null;
    } catch (e) {
      print("Error loading playlist: $e");
      return null;
    }
  }

  void loadPlaylistForTitle(String title) async {
    _playlistId = await getPlaylistIdByTitle(title) ?? '';
  }

  String formatViewCount(int count) {
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B views';
    } else if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M views';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K views';
    } else {
      return '$count views';
    }
  }

  Future<void> _addToHistory({required double progress}) async {
    final watchDuration = DateTime.now().difference(_startWatchTime!).inSeconds;

    await widget.historyService.addToHistory(
      HistoryItem(
        videoId: widget.videoId,
        title: widget.title,

        thumbnailUrl:
            'https://img.youtube.com/vi/${widget.videoId}/mqdefault.jpg',
        watchedAt: DateTime.now(),
        playlistTitle: widget.playlistTitle,
        viewCount: int.tryParse(widget.viewCount) ?? 0,
        watchDurationInSeconds: watchDuration,
        totalDurationInSeconds: _totalDuration,
        watchProgress: progress,
        lastPositionInSeconds: _currentPosition,
      ),
    );
  }

  Future<void> _updateHistoryProgress({
    required double progress,
    bool isFinal = false,
  }) async {
    final watchDuration =
        isFinal ? DateTime.now().difference(_startWatchTime!).inSeconds : null;

    final List<HistoryItem> historyItems =
        await widget.historyService.getHistory();
    final HistoryItem? existingItem = historyItems.firstWhere(
      (item) => item.videoId == widget.videoId,
      orElse: () => null as HistoryItem,
    );

    if (existingItem != null) {
      final updatedItem = existingItem.copyWith(
        watchProgress: progress,
        lastPositionInSeconds: _currentPosition,
        watchDurationInSeconds:
            watchDuration ?? existingItem.watchDurationInSeconds,
        watchedAt:
            isFinal
                ? DateTime.now()
                : null, // Update timestamp only on final update
      );

      await widget.historyService.updateHistoryItem(updatedItem);
    }
  }
}
