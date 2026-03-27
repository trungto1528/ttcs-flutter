class Block {
  final String type;
  final String content;

  Block({required this.type, required this.content});

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      type: json['type'],
      content: json["data"]
    );
  }
}