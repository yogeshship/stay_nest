import 'package:flutter/material.dart';

import '../models/room_model.dart';

class RoomImage extends StatelessWidget {
  const RoomImage({
    super.key,
    required this.source,
    required this.height,
    required this.width,
    this.fit = BoxFit.cover,
  });

  final String source;
  final double height;
  final double width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (isNetworkRoomImageSource(source)) {
      return Image.network(
        source,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: height,
            width: width,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return Image.asset(
      source.isEmpty ? RoomModel.fallbackAsset : source,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Image.asset(
      RoomModel.fallbackAsset,
      height: height,
      width: width,
      fit: fit,
    );
  }
}

bool isNetworkRoomImageSource(String source) =>
    source.startsWith('http://') || source.startsWith('https://');
