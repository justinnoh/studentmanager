class StudentModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? parentName;
  final String? parentPhone;
  final int? age;
  final String? gender;
  final String role;

  StudentModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.parentName,
    this.parentPhone,
    this.age,
    this.gender,
    required this.role,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      email: json['email'],
      name: json['name'] ?? '',
      phone: json['phone'],
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      age: json['age'],
      gender: json['gender'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'age': age,
      'gender': gender,
      'role': role,
    };
  }
}
