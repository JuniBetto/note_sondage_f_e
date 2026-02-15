class UserEntity {
  final String? id;
  final String fullName;
  final String email;
  final DateTime createdAt;

  UserEntity(
    this.id, {
    required this.fullName,
    required this.email,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

// class UserEntityForUpdate {
//   final String? id;
//   final String fullName;
//   final String email;
//   final DateTime createdAt;
//   final bool isActive;
//   final String teamMemberId;
//   final String? imageUrl;
//   final String role;
//   final String status;

//   UserEntityForUpdate({
//     this.id,
//     required this.fullName,
//     required this.email,
//     DateTime? createdAt,
//     required this.isActive,
//     required this.teamMemberId,
//     required this.role,
//     required this.status,
//     this.imageUrl,
//   }) : createdAt = createdAt ?? DateTime.now();
// }

class UserEntityForUpdate extends UserEntity {
  final bool isActive;
  final String teamMemberId;
  final String? imageUrl;
  final String role;
  final String status;

  UserEntityForUpdate(
    String? id, {
    required String fullName,
    required String email,
    DateTime? createdAt,
    required this.isActive,
    required this.teamMemberId,
    required this.role,
    required this.status,
    this.imageUrl,
  }) : super(
         id,
         fullName: fullName,
         email: email,
         createdAt: createdAt ?? DateTime.now(),
       );
}
