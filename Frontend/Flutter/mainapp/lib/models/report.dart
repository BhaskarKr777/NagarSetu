class Report {
  final int id;
  final String title;
  final String description;
  final String category;
  final String? mediaUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String status;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.mediaUrl,
    this.latitude,
    this.longitude,
    this.address,
    required this.status,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      mediaUrl: json['media_url']?.toString(),
      latitude: json['latitude'] != null ? 
        (json['latitude'] is double ? json['latitude'] : double.tryParse(json['latitude'].toString())) : null,
      longitude: json['longitude'] != null ? 
        (json['longitude'] is double ? json['longitude'] : double.tryParse(json['longitude'].toString())) : null,
      address: json['address']?.toString(),
      status: json['status']?.toString() ?? 'Open',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'media_url': mediaUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Report{id: $id, title: $title, category: $category, status: $status}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Report &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Report copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? mediaUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? status,
    DateTime? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}