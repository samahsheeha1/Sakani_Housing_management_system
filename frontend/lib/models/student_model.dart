class Student {
  String id;
  String fullName;
  String email;
  String password;
  String phone;
  String address;
  int age;
  List<String> interests;
  String photo;
  String status;
  String? matchedWith;
  String role;
  List<Map<String, dynamic>> documents; // Change to List<Map<String, dynamic>>

  Student({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    required this.age,
    required this.interests,
    required this.photo,
    required this.status,
    required this.matchedWith,
    required this.role,
    required this.documents,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'],
      fullName: json['fullName'],
      email: json['email'],
      password: json['password'],
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      age: json['age'] ?? 0,
      interests: List<String>.from(json['interests'] ?? []),
      photo: json['photo'] ?? '',
      status: json['status'] ?? 'Available',
      matchedWith: json['matchedWith'],
      role: json['role'],
      documents: (json['documents'] as List<dynamic>?)?.map((doc) {
            return doc as Map<String, dynamic>;
          }).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
      'phone': phone,
      'address': address,
      'age': age,
      'interests': interests,
      'photo': photo,
      'status': status,
      'matchedWith': matchedWith,
      'role': role,
      'documents': documents,
    };
  }
}
