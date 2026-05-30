class BrandModel {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final bool isActive;

  BrandModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.isActive,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'is_active': isActive,
    };
  }
}
