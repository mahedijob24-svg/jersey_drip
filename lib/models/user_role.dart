enum UserRole {
  user,
  admin,
  superadmin;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
        return UserRole.superadmin;
      default:
        return UserRole.user;
    }
  }

  static String toStringValue(UserRole role) {
    return role.name;
  }
}
