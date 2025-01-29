class Document {
  final String id;
  final String name;
  final String path;
  final String mimetype;
  final String description;

  Document({
    required this.id,
    required this.name,
    required this.path,
    required this.mimetype,
    required this.description,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['_id'],
      name: json['name'],
      path: json['path'],
      mimetype: json['mimetype'],
      description: json['description'],
    );
  }
}
