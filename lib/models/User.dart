class User {
  final int id;
  final String username;
  String avatarUrl;
  String displayName;
  final int lastReadStoryId;
  final int lastReadChapterId;
  final int lastReadCreatedById;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.displayName,
    required this.lastReadStoryId,
    required this.lastReadChapterId,
    required this.lastReadCreatedById,
    required this.role
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      username: json["username"],
      avatarUrl: json["avatarUrl"],
      displayName: json['displayName'],
      lastReadStoryId: json['lastReadStoryId'],
      lastReadChapterId: json['lastReadChapterId'],
      lastReadCreatedById: json['lastReadCreatedById'],
      role: json['role']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "username": username,
      "avatarUrl": avatarUrl,
      "displayName":displayName,
      "lastReadStoryId":lastReadStoryId,
      "lastReadChapterId":lastReadChapterId,
      'lastReadCreatedById':lastReadCreatedById,
      'role': role
    };
  }
}