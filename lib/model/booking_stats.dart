class BookingStats {
  final int bookingLimitFrequencyCount; // allowed hours per period
  final String bookingLimitFrequencyUnit; // "HOR" - hours
  final int bookingLimitPeriodBookingCount; // amount of bookings
  final double bookingLimitPeriodBookingHour; // booked hours
  final int bookingLimitPeriodCount; // duration of period in Weeks
  final String bookingLimitPeriodUnit; // "WEK" - weeks
  final String bookingLimitViolation;
  final int bookingTotalCount;
  final double bookingTotalHour;
  final String cateName;

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
