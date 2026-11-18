import 'package:collection/collection.dart';

import '../utils/date_parsing.dart';

/// Why a student reports another one. Shown as a list on the Report or block
/// screen.
enum ReportReason {
  fakeProfile('Fake profile', 'The photo or details are not a real student'),
  harassment('Harassment', 'Threats, insults or unwanted messages'),
  inappropriate('Inappropriate content', 'Offensive photo, bio or messages'),
  spam('Spam or scam', 'Advertising, links or asking for money'),
  other('Something else', 'Tell us what happened');

  final String label;
  final String description;

  const ReportReason(this.label, this.description);

  static ReportReason fromName(String? name) =>
      ReportReason.values.firstWhereOrNull((r) => r.name == name) ??
      ReportReason.other;
}

/// A report about another student, stored at `reports/{id}`. Only the
/// reporter can create it; moderators read it.
class Report {
  final String id;
  final String reporterUid;
  final String reportedUid;
  final ReportReason reason;

  /// Free text from the reporter. Required for [ReportReason.other].
  final String details;

  /// Whether the reporter also blocked the student.
  final bool blocked;
  final DateTime? createdAt;

  const Report({
    required this.id,
    required this.reporterUid,
    required this.reportedUid,
    required this.reason,
    this.details = '',
    this.blocked = false,
    this.createdAt,
  });

  /// [id] is the document id; falls back to `map['id']`.
  factory Report.fromMap(Map<String, dynamic> map, {String? id}) => Report(
    id: id ?? map['id'] as String? ?? '',
    reporterUid: map['reporterUid'] as String? ?? '',
    reportedUid: map['reportedUid'] as String? ?? '',
    reason: ReportReason.fromName(map['reason'] as String?),
    details: map['details'] as String? ?? '',
    blocked: map['blocked'] as bool? ?? false,
    createdAt: parseDate(map['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'reporterUid': reporterUid,
    'reportedUid': reportedUid,
    'reason': reason.name,
    'details': details,
    'blocked': blocked,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Report &&
      other.id == id &&
      other.reporterUid == reporterUid &&
      other.reportedUid == reportedUid &&
      other.reason == reason &&
      other.details == details &&
      other.blocked == blocked &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    reporterUid,
    reportedUid,
    reason,
    details,
    blocked,
    createdAt,
  );
}
