class AppointmentDepartment {
  const AppointmentDepartment({required this.code, required this.name});
  final String code;
  final String name;

  factory AppointmentDepartment.fromJson(Map<String, dynamic> json) {
    final code = json['code'];
    final name = json['name'];
    if (code is! String || name is! String) {
      throw const FormatException('진료과 형식이 올바르지 않습니다.');
    }
    return AppointmentDepartment(code: code, name: name);
  }
}

class WeeklySchedule {
  const WeeklySchedule({
    required this.dayOfWeek,
    required this.period,
    required this.available,
  });
  final String dayOfWeek;
  final String period;
  final bool available;

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    final day = json['day_of_week'];
    final period = json['period'];
    final available = json['available'];
    if (day is! String || period is! String || available is! bool) {
      throw const FormatException('의료진 일정 형식이 올바르지 않습니다.');
    }
    return WeeklySchedule(dayOfWeek: day, period: period, available: available);
  }
}

class AppointmentDoctor {
  const AppointmentDoctor({
    required this.id,
    required this.name,
    required this.department,
    required this.photoUrl,
    required this.specialtyTags,
    required this.isAssigned,
    required this.weeklySchedule,
  });
  final String id;
  final String name;
  final String department;
  final String? photoUrl;
  final List<String> specialtyTags;
  final bool isAssigned;
  final List<WeeklySchedule> weeklySchedule;

  factory AppointmentDoctor.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final department = json['department'];
    final photo = json['photo_url'];
    final tags = json['specialty_tags'];
    final assigned = json['is_assigned'];
    final schedule = json['weekly_schedule'];
    if (id is! String ||
        name is! String ||
        department is! String ||
        (photo != null && photo is! String) ||
        tags is! List<dynamic> ||
        tags.any((item) => item is! String) ||
        assigned is! bool ||
        schedule is! List<dynamic>) {
      throw const FormatException('의료진 형식이 올바르지 않습니다.');
    }
    return AppointmentDoctor(
      id: id,
      name: name,
      department: department,
      photoUrl: photo as String?,
      specialtyTags: List<String>.unmodifiable(tags.cast<String>()),
      isAssigned: assigned,
      weeklySchedule: schedule
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('의료진 일정은 객체여야 합니다.');
            }
            return WeeklySchedule.fromJson(item);
          })
          .toList(growable: false),
    );
  }
}

class AppointmentSlot {
  const AppointmentSlot({
    required this.time,
    required this.dateTime,
    required this.dateTimeValue,
    required this.status,
  });
  final String time;
  final DateTime dateTime;
  final String dateTimeValue;
  final String status;

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    final time = json['time'];
    final value = json['datetime'];
    final status = json['status'];
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (time is! String || parsed == null || status is! String) {
      throw const FormatException('예약 시간 형식이 올바르지 않습니다.');
    }
    return AppointmentSlot(
      time: time,
      dateTime: parsed,
      dateTimeValue: value,
      status: status,
    );
  }
}

class AppointmentSlots {
  const AppointmentSlots({
    required this.date,
    required this.timezone,
    required this.slots,
  });
  final DateTime date;
  final String timezone;
  final List<AppointmentSlot> slots;

  factory AppointmentSlots.fromJson(Map<String, dynamic> json) {
    final dateValue = json['date'];
    final timezone = json['timezone'];
    final slotsValue = json['slots'];
    final date = dateValue is String ? DateTime.tryParse(dateValue) : null;
    if (date == null || timezone is! String || slotsValue is! List<dynamic>) {
      throw const FormatException('예약 슬롯 응답 형식이 올바르지 않습니다.');
    }
    return AppointmentSlots(
      date: date,
      timezone: timezone,
      slots: slotsValue
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('예약 슬롯은 객체여야 합니다.');
            }
            return AppointmentSlot.fromJson(item);
          })
          .toList(growable: false),
    );
  }
}
