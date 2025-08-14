class Song {
  final String name;
  final String url;

  Song({required this.name, required this.url});

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(name: json['name'] ?? '', url: json["url"] ?? '');
  }
}
