class Comment {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });
  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] ?? '',
    content: json['content'] ?? '',
    authorId: json['authorId'] ?? json['author_id'] ?? '',
    authorName: json['authorName'] ?? json['author_name'] ?? 'Unknown',
    createdAt: json['createdAt'] != null 
      ? DateTime.parse(json['createdAt']) 
      : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
  );
}