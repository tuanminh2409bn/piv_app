// lib/data/models/content_block_model.dart
class ContentBlock {
  String type;
  Map<String, dynamic> data;

  ContentBlock({required this.type, required this.data});

  Map<String, dynamic> toJson() => {'type': type, 'data': data};

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }
}