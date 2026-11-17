import '../api_list.dart';
import '../auth/session.dart';

/// A time zone a project may be in, as the API offers it (redix-app #107, D3): its IANA name, the word naming its city, and how far it is ahead of UTC now.
class TimeZoneOption {
  /// The zone the API describes in [json].
  TimeZoneOption.fromJson(Map<String, dynamic> json) : name = json['name'] as String, wordKey = json['wordKey'] as String, utcOffsetMinutes = json['utcOffsetMinutes'] as int;

  /// The IANA name a project keeps: Asia/Riyadh.
  final String name;

  /// The word naming its city.
  final String wordKey;

  /// How far it is ahead of UTC now, in minutes.
  final int utcOffsetMinutes;
}

/// The zones a project may be in, Saudi Arabia first: the API holds the list, the app only shows it.
class TimeZones extends ApiList<TimeZoneOption> {
  /// The zones, read through [session].
  TimeZones(Session session) : super(session, '/time-zones', 'projects', TimeZoneOption.fromJson);
}

/// [minutes] ahead of UTC as a reader writes it: UTC+3, UTC+5:30, UTC−8.
String utcOffsetText(int minutes) {
  final sign = minutes < 0 ? '−' : '+';
  final hours = minutes.abs() ~/ 60;
  final rest = minutes.abs() % 60;
  return 'UTC$sign$hours${rest == 0 ? '' : ':${rest.toString().padLeft(2, '0')}'}';
}
