// lib/models/user_role.dart
enum UserRole {
  guest, // برای کاربران مهمان (لاگین نکرده)
  normaluser, // برای کاربران عادی (ثبت‌نام شده)
  student, // برای دانشجویان (دعوت شده توسط استاد)
  instructor, // برای اساتید
  moderator, // برای ناظران
  admin, // برای ادمین‌ها
}

extension UserRoleExtension on UserRole {
  String get persianName {
    switch (this) {
      case UserRole.guest:
        return 'مهمان';
      case UserRole.normaluser:
        return 'کاربر عادی';
      case UserRole.student:
        return 'دانشجو';
      case UserRole.instructor:
        return 'استاد';
      case UserRole.moderator:
        return 'ناظر';
      case UserRole.admin:
        return 'مدیر';
    }
  }

  int get level {
    switch (this) {
      case UserRole.guest:
        return 0;
      case UserRole.normaluser:
        return 1;
      case UserRole.student:
        return 2;
      case UserRole.instructor:
        return 3;
      case UserRole.moderator:
        return 4;
      case UserRole.admin:
        return 5;
    }
  }

  String get uid {
    switch (this) {
      case UserRole.guest:
        return 'guest';
      case UserRole.normaluser:
        return 'normal_user';
      case UserRole.student:
        return 'student';
      case UserRole.instructor:
        return 'instructor';
      case UserRole.moderator:
        return 'moderator';
      case UserRole.admin:
        return 'admin';
    }
  }

  bool hasAccess(UserRole requiredRole) {
    return level >= requiredRole.level;
  }
}
