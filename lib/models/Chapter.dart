class Chapter {
  final int id;
  final String title;
  final int chapterNumber;

  Chapter({
    required this.id,
    required this.title,
    required this.chapterNumber,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      title: json['title'],
      chapterNumber: json['chapterNumber'],
    );
  }
}