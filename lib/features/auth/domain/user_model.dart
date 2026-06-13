enum UserRole { owner, manager, karyawan }

extension UserRoleExt on UserRole {
  String get name => switch (this) {
        UserRole.owner => 'owner',
        UserRole.manager => 'manager',
        UserRole.karyawan => 'karyawan',
      };

  String get label => switch (this) {
        UserRole.owner => 'Owner',
        UserRole.manager => 'Manager',
        UserRole.karyawan => 'Karyawan',
      };

  static UserRole fromString(String s) {
    return switch (s.toLowerCase()) {
      'owner' => UserRole.owner,
      'manager' => UserRole.manager,
      _ => UserRole.karyawan,
    };
  }

  // Access control helpers
  bool get canViewDashboard =>
      this == UserRole.owner || this == UserRole.manager;
  bool get canViewProducts =>
      this == UserRole.owner || this == UserRole.manager;
  bool get canViewStok =>
      this == UserRole.owner || this == UserRole.manager;
  bool get canCancelDirect =>
      this == UserRole.owner || this == UserRole.manager;
  bool get canApproveCancelRefund =>
      this == UserRole.owner || this == UserRole.manager;
  bool get canManageRoles => this == UserRole.owner;
  bool get canManageSubscription => this == UserRole.owner;
  bool get canManageOutlet => this == UserRole.owner;
  bool get canEditReceipt =>
      this == UserRole.owner || this == UserRole.manager;
  bool get canManageTaxDiscount =>
      this == UserRole.owner || this == UserRole.manager;
  bool get canViewAuditLog =>
      this == UserRole.owner || this == UserRole.manager;
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatar;
  final String businessId;
  final String businessName;
  final bool emailVerified;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    required this.businessId,
    required this.businessName,
    this.emailVerified = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRoleExt.fromString(json['role'] as String? ?? 'karyawan'),
        avatar: json['avatar'] as String?,
        businessId: json['business_id'].toString(),
        businessName: json['business_name'] as String? ?? '',
        emailVerified: json['email_verified_at'] != null,
      );
}
