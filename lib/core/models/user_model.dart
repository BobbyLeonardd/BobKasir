enum UserRole { owner, admin, cashier }

enum UserStatus { active, inactive }

class TenantInfo {
  final String id;
  final String shopName;
  final String subscriptionStatus; // trial | active | expired
  final DateTime? trialUntil;
  final DateTime? subscriptionExpiresAt;
  final bool hasFullAccess;

  const TenantInfo({
    required this.id,
    required this.shopName,
    required this.subscriptionStatus,
    this.trialUntil,
    this.subscriptionExpiresAt,
    required this.hasFullAccess,
  });

  factory TenantInfo.fromJson(Map<String, dynamic> j) {
    return TenantInfo(
      id: j['id'].toString(),
      shopName: j['shop_name'] ?? '',
      subscriptionStatus: j['subscription_status'] ?? 'trial',
      trialUntil: j['trial_until'] != null ? DateTime.tryParse(j['trial_until']) : null,
      subscriptionExpiresAt: j['subscription_expires_at'] != null
          ? DateTime.tryParse(j['subscription_expires_at'])
          : null,
      hasFullAccess: j['has_full_access'] == true,
    );
  }
}

class UserModel {
  final String id;
  final String tenantId;
  final UserRole role;
  final String name;
  final String email;
  final bool emailVerified;
  final UserStatus status;
  final TenantInfo? tenant;

  const UserModel({
    required this.id,
    required this.tenantId,
    required this.role,
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.status,
    this.tenant,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isAdmin => role == UserRole.admin;
  bool get isCashier => role == UserRole.cashier;
  bool get canViewDashboard => role == UserRole.owner || role == UserRole.admin;
  bool get canManageProducts => role == UserRole.owner || role == UserRole.admin;
  bool get canManageUsers => role == UserRole.owner;
  bool get canManageSubscription => role == UserRole.owner;
  bool get canCancelOrder => role == UserRole.owner || role == UserRole.admin;

  String get roleLabel {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.cashier:
        return 'Kasir';
    }
  }

  UserModel copyWith({TenantInfo? tenant}) => UserModel(
        id: id,
        tenantId: tenantId,
        role: role,
        name: name,
        email: email,
        emailVerified: emailVerified,
        status: status,
        tenant: tenant ?? this.tenant,
      );

  static UserModel mock = const UserModel(
    id: 'usr_1',
    tenantId: 'tenant_1',
    role: UserRole.owner,
    name: 'Bobby Owner',
    email: 'owner@kedaikopi.id',
    emailVerified: true,
    status: UserStatus.active,
  );
}
