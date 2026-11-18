/// A student's own profile, as filled in on the Basic profile screen.
///
/// [studentId] is private: it is shown only to the confirmed roommate, never
/// on match cards.
class AppUser {
  final String uid;
  final String email;
  final String name;
  final String gender;
  final String program;

  /// 0 means the preparatory year.
  final int year;
  final String bio;
  final String studentId;

  /// Uploaded photo (Firebase Storage in Step 3).
  final String? photoUrl;

  /// A photo picked on this phone and not uploaded yet, shown as a preview.
  final String? localPhotoPath;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.gender,
    required this.program,
    required this.year,
    this.bio = '',
    required this.studentId,
    this.photoUrl,
    this.localPhotoPath,
  });

  static const List<String> genders = ['Female', 'Male', 'Prefer not to say'];

  /// Year options for the profile form; 0 is shown as "Prep".
  static const List<int> years = [0, 1, 2, 3, 4, 5];

  static String yearLabel(int year) => year == 0 ? 'Prep' : 'Year $year';

  /// Undergraduate programs at Sabanci University.
  static const List<String> programs = [
    'Computer Science and Engineering',
    'Electronics Engineering',
    'Industrial Engineering',
    'Materials Science and Nano Engineering',
    'Mechatronics Engineering',
    'Molecular Biology, Genetics and Bioengineering',
    'Economics',
    'Management',
    'Political Science',
    'Psychology',
    'Social and Political Sciences',
    'Visual Arts and Visual Communication Design',
    'Undecided',
  ];

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: uid,
    email: map['email'] as String? ?? '',
    name: map['name'] as String? ?? '',
    gender: map['gender'] as String? ?? '',
    program: map['program'] as String? ?? '',
    year: (map['year'] as num?)?.toInt() ?? 0,
    bio: map['bio'] as String? ?? '',
    studentId: map['studentId'] as String? ?? '',
    photoUrl: map['photoUrl'] as String?,
  );

  /// The local photo path is not stored; it is uploaded and replaced by
  /// [photoUrl] instead.
  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'gender': gender,
    'program': program,
    'year': year,
    'bio': bio,
    'studentId': studentId,
    'photoUrl': photoUrl,
  };

  AppUser copyWith({
    String? email,
    String? name,
    String? gender,
    String? program,
    int? year,
    String? bio,
    String? studentId,
    String? photoUrl,
    String? localPhotoPath,
  }) => AppUser(
    uid: uid,
    email: email ?? this.email,
    name: name ?? this.name,
    gender: gender ?? this.gender,
    program: program ?? this.program,
    year: year ?? this.year,
    bio: bio ?? this.bio,
    studentId: studentId ?? this.studentId,
    photoUrl: photoUrl ?? this.photoUrl,
    localPhotoPath: localPhotoPath ?? this.localPhotoPath,
  );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.email == email &&
      other.name == name &&
      other.gender == gender &&
      other.program == program &&
      other.year == year &&
      other.bio == bio &&
      other.studentId == studentId &&
      other.photoUrl == photoUrl &&
      other.localPhotoPath == localPhotoPath;

  @override
  int get hashCode => Object.hash(
    uid,
    email,
    name,
    gender,
    program,
    year,
    bio,
    studentId,
    photoUrl,
    localPhotoPath,
  );
}
