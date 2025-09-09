class PasswordChangeRequest {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  const PasswordChangeRequest({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'old_password': oldPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    };
  }
}

class PasswordResetRequest {
  final String newPassword;

  const PasswordResetRequest({
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'new_password': newPassword,
    };
  }
}
