class Playlist {
  final String title;
  final String id;

  Playlist({required this.title, required this.id});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      title: json['title'],
      id: json['id'],
    );
  }
}
