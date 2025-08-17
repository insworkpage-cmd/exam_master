// lib/models/user_role.dart

enum UserRole {
  guest,
  registeredUser,
  student,
  instructor,
  contentModerator,
  admin,
  superAdmin,
}

extension UserRoleExtension on UserRole {
  String get persianName {
    switch (this) {
      case UserRole.guest:
        return 'مهمان';
      case UserRole.registeredUser:
        return 'کاربر ثبت‌نام شده';
      case UserRole.student:
        return 'دانشجو';
      case UserRole.instructor:
        return 'مدرس';
      case UserRole.contentModerator:
        return 'ناظر محتوا';
      case UserRole.admin:
        return 'مدیر';
      case UserRole.superAdmin:
        return 'مدیر ارشد';
    }
  }

  int get level {
    switch (this) {
      case UserRole.guest:
        return 0;
      case UserRole.registeredUser:
        return 1;
      case UserRole.student:
        return 2;
      case UserRole.instructor:
        return 3;
      case UserRole.contentModerator:
        return 4;
      case UserRole.admin:
        return 5;
      case UserRole.superAdmin:
        return 6;
    }
  }

  // اضافه کردن گتر uid برای دسترسی به شناسه کاربر
  String get uid {
    // این یک شناسه منحصر به فرد برای هر نقش است
    switch (this) {
      case UserRole.guest:
        return 'guest';
      case UserRole.registeredUser:
        return 'registered_user';
      case UserRole.student:
        return 'student';
      case UserRole.instructor:
        return 'instructor';
      case UserRole.contentModerator:
        return 'content_moderator';
      case UserRole.admin:
        return 'admin';
      case UserRole.superAdmin:
        return 'super_admin';
    }
  }

  // متد کمکی برای بررسی دسترسی
  bool hasAccess(UserRole requiredRole) {
    return level >= requiredRole.level;
  }
}
