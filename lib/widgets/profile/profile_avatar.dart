import 'dart:io';

import 'package:flutter/material.dart';

import '../matches/match_card.dart';

/// The student's own round photo. Shows a photo just picked on this phone
/// ([localPhotoPath]) if there is one, otherwise the uploaded [photoUrl]
/// from the network, with initials as the fallback (via [MatchAvatar]).
class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String? localPhotoPath;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.localPhotoPath,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final network = MatchAvatar(photoUrl: photoUrl, name: name, size: size);
    final path = localPhotoPath;
    if (path == null) return network;
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => network,
        ),
      ),
    );
  }
}
