// screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:my_app/screens/downloads_screen.dart';
import 'package:my_app/screens/home_screen.dart';
import 'package:my_app/screens/more_screen.dart';
import '../history_service.dart';
import '../models/history_model.dart';
import 'video_player_screen.dart';

class HistoryScreen extends StatefulWidget {
  final HistoryService historyService;

  const HistoryScreen({required this.historyService, Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<List<HistoryItem>>? _historyFuture;
  final HistoryService _historyService = HistoryService();
  int _selectedIndex = 1;
  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }
  
  void _refreshHistory() {
    setState(() {
      _historyFuture = widget.historyService.getHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      appBar: AppBar(
        title: Text('Watch History', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: () async {
              await _showClearHistoryDialog();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<HistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.red));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[700]),
                  SizedBox(height: 16),
                  Text(
                    'No watch history yet',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Videos you watch will appear here',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }
          
          final history = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: () async {
              _refreshHistory();
            },
            color: Colors.red,
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Dismissible(
                  key: Key(item.videoId + item.watchedAt.toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20.0),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    await widget.historyService.removeFromHistory(item.videoId);
                    setState(() {
                      history.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Removed from history')),
                    );
                  },
                  child: _buildHistoryItem(context, item),
                );
              },
            ),
          );
        },
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
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => HistoryScreen(historyService: _historyService), // <- create this screen
      ));
    } else if (index == 2) {
      // Navigate to Downloads screen
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => DownloadsScreen(), // <- create this screen
      ));
    } else if (index == 3) {
      // Navigate to More screen
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => MoreScreen(), // <- create this screen
      ));
    }
  },
  type: BottomNavigationBarType.fixed,
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
    BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Downloads'),
    BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
  ],
),
    );
  }
  
  Widget _buildHistoryItem(BuildContext context, HistoryItem item) {
    // Calculate progress percentage for the progress bar
    double progressPercent = item.watchProgress.clamp(0.0, 100.0) / 100;
    
    // Format durations for display
    final String watchedDuration = _formatDuration(Duration(seconds: item.lastPositionInSeconds));
    final String totalDuration = _formatDuration(Duration(seconds: item.totalDurationInSeconds));
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[900],
      child: ListTile(
        contentPadding: EdgeInsets.all(8),
        leading: Stack(
          children: [
            Container(
              width: 100,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  item.thumbnailUrl, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                ),
              ),
            ),
            if (item.watchProgress > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  minHeight: 3,
                ),
              ),
            if (item.lastPositionInSeconds > 0)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '$watchedDuration / $totalDuration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          item.title, 
          style: TextStyle(color: Colors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  _timeAgo(item.watchedAt),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(width: 16),
                if (item.playlistTitle != null) ...[
                  Icon(Icons.playlist_play, size: 12, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.playlistTitle!,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (item.watchProgress > 0) ...[
              SizedBox(height: 4),
              Text(
                item.watchProgress >= 90 
                    ? 'Watched fully' 
                    : 'Watched ${item.watchProgress.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: item.watchProgress >= 90 ? Colors.green : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                videoId: item.videoId,
                title: item.title,
                viewCount: item.viewCount.toString(),
                playlistTitle: item.playlistTitle ?? 'Unknown Playlist',
                historyService: widget.historyService,
              ),
            ),
          ).then((_) => _refreshHistory());
        },
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.white),
          color: Colors.grey[850],
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Remove from history', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            if (item.lastPositionInSeconds > 0 && item.watchProgress < 95)
              PopupMenuItem(
                value: 'resume',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Resume watching', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
          ],
          onSelected: (value) async {
            if (value == 'remove') {
              await widget.historyService.removeFromHistory(item.videoId);
              _refreshHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removed from history')),
              );
            } else if (value == 'resume') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(
                    videoId: item.videoId,
                    title: item.title,
                    viewCount: item.viewCount.toString(),
                    playlistTitle: item.playlistTitle ?? 'Unknown Playlist',
                    historyService: widget.historyService,
                  ),
                ),
              ).then((_) => _refreshHistory());
            }
          },
        ),
      ),
    );
  }

  Future<void> _showClearHistoryDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Clear History', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to clear your entire watch history?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Clear', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await widget.historyService.clearHistory();
              _refreshHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('History cleared')),
              );
            },
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inSeconds == 0) return '--:--';
    
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }
}