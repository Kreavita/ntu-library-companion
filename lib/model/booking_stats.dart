class BookingStats {
  final int bookingLimitFrequencyCount; // allowed hours per period
  final String bookingLimitFrequencyUnit; // "HOR" - hours, "TIM" - times
  final int bookingLimitPeriodBookingCount; // amount of bookings
  final double bookingLimitPeriodBookingHour; // booked hours
  final int bookingLimitPeriodCount; // duration of period in Weeks
  final String bookingLimitPeriodUnit; // "WEK" - weeks, "MON" - months
  final String bookingLimitViolation;
  final int bookingTotalCount;
  final double bookingTotalHour;
  final String cateName;

  get friendlyLimitUnit =>
      {"HOR": "hrs", "TIM": "reservations"}[bookingLimitFrequencyUnit];

  get friendlyPeriodUnit =>
      {"WEK": "weeks", "MON": "months"}[bookingLimitPeriodUnit];

  BookingStats.fromJson(Map<String, dynamic> json)
    : bookingLimitFrequencyCount = json['bookingLimitFrequencyCount'],
      bookingLimitFrequencyUnit = json['bookingLimitFrequencyUnit'],
      bookingLimitPeriodBookingCount = json['bookingLimitPeriodBookingCount'],
      bookingLimitPeriodBookingHour = json['bookingLimitPeriodBookingHour'],
      bookingLimitPeriodCount = json['bookingLimitPeriodCount'],
      bookingLimitPeriodUnit = json['bookingLimitPeriodUnit'],
      bookingLimitViolation = json['bookingLimitViolation'],
      bookingTotalCount = json['bookingTotalCount'],
      bookingTotalHour = json['bookingTotalHour'],
      cateName = json['cateName'];

  @override
  String toString() {
    return 'BookingStats(bookingLimitFrequencyCount: $bookingLimitFrequencyCount, '
        'bookingLimitFrequencyUnit: $bookingLimitFrequencyUnit, '
        'bookingLimitPeriodBookingCount: $bookingLimitPeriodBookingCount, '
        'bookingLimitPeriodBookingHour: $bookingLimitPeriodBookingHour, '
        'bookingLimitPeriodCount: $bookingLimitPeriodCount, '
        'bookingLimitPeriodUnit: $bookingLimitPeriodUnit, '
        'bookingLimitViolation: $bookingLimitViolation, '
        'bookingTotalCount: $bookingTotalCount, '
        'bookingTotalHour: $bookingTotalHour, '
        'cateName: $cateName)';
  }
}
