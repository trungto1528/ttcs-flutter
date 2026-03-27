class Story {
  final int id;
  final String title;
  final String? coverUrl;

  Story({required this.id, required this.title, this.coverUrl});

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      title: json['title'],
      coverUrl: json['coverUrl'],
    );
  }
}