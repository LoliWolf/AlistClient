import 'package:alist/util/constant.dart';
import 'package:flustars/flustars.dart';

enum ProjectorTraversalMode {
  orderedDfs,
  randomWalk,
  randomAllTree,
}

class ProjectorConfig {
  static const int maxPreloadCount = 20;

  final ProjectorTraversalMode traversalMode;
  final int imageStaySeconds;
  final int videoStaySeconds;
  final int audioStaySeconds;
  final int preloadCount;
  final bool videoStayInfinite;
  final bool audioStayInfinite;

  const ProjectorConfig({
    required this.traversalMode,
    required this.imageStaySeconds,
    required this.videoStaySeconds,
    required this.audioStaySeconds,
    required this.preloadCount,
    required this.videoStayInfinite,
    required this.audioStayInfinite,
  });

  const ProjectorConfig.defaults()
      : traversalMode = ProjectorTraversalMode.orderedDfs,
        imageStaySeconds = 8,
        videoStaySeconds = 30,
        audioStaySeconds = 30,
        preloadCount = 2,
        videoStayInfinite = true,
        audioStayInfinite = true;

  ProjectorConfig copyWith({
    ProjectorTraversalMode? traversalMode,
    int? imageStaySeconds,
    int? videoStaySeconds,
    int? audioStaySeconds,
    int? preloadCount,
    bool? videoStayInfinite,
    bool? audioStayInfinite,
  }) {
    return ProjectorConfig(
      traversalMode: traversalMode ?? this.traversalMode,
      imageStaySeconds: imageStaySeconds ?? this.imageStaySeconds,
      videoStaySeconds: videoStaySeconds ?? this.videoStaySeconds,
      audioStaySeconds: audioStaySeconds ?? this.audioStaySeconds,
      preloadCount: preloadCount ?? this.preloadCount,
      videoStayInfinite: videoStayInfinite ?? this.videoStayInfinite,
      audioStayInfinite: audioStayInfinite ?? this.audioStayInfinite,
    );
  }

  Map<String, dynamic> toArgs() {
    return {
      "traversalMode": traversalMode.index,
      "imageStaySeconds": imageStaySeconds,
      "videoStaySeconds": videoStaySeconds,
      "audioStaySeconds": audioStaySeconds,
      "preloadCount": preloadCount,
      "videoStayInfinite": videoStayInfinite,
      "audioStayInfinite": audioStayInfinite,
    };
  }

  factory ProjectorConfig.fromArgs(Map<String, dynamic> args) {
    const defaults = ProjectorConfig.defaults();
    return ProjectorConfig(
      traversalMode: _parseMode(args["traversalMode"], defaults.traversalMode),
      imageStaySeconds: _parsePositiveInt(
          args["imageStaySeconds"], defaults.imageStaySeconds),
      videoStaySeconds: _parsePositiveInt(
          args["videoStaySeconds"], defaults.videoStaySeconds),
      audioStaySeconds: _parsePositiveInt(
          args["audioStaySeconds"], defaults.audioStaySeconds),
      preloadCount: _normalizePreloadCount(
          _parseNonNegativeInt(args["preloadCount"], defaults.preloadCount)),
      videoStayInfinite:
          _parseBool(args["videoStayInfinite"], defaults.videoStayInfinite),
      audioStayInfinite:
          _parseBool(args["audioStayInfinite"], defaults.audioStayInfinite),
    );
  }

  static ProjectorTraversalMode _parseMode(
      dynamic value, ProjectorTraversalMode fallback) {
    if (value is int &&
        value >= 0 &&
        value < ProjectorTraversalMode.values.length) {
      return ProjectorTraversalMode.values[value];
    }
    return fallback;
  }

  static int _parsePositiveInt(dynamic value, int fallback) {
    if (value is int && value > 0) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return fallback;
  }

  static int _parseNonNegativeInt(dynamic value, int fallback) {
    if (value is int && value >= 0) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed >= 0) {
        return parsed;
      }
    }
    return fallback;
  }

  static int _normalizePreloadCount(int value) {
    return value.clamp(0, maxPreloadCount).toInt();
  }

  static bool _parseBool(dynamic value, bool fallback) {
    if (value is bool) {
      return value;
    }
    return fallback;
  }
}

class ProjectorConfigStore {
  static ProjectorConfig load() {
    const defaults = ProjectorConfig.defaults();
    final modeIndex = SpUtil.getInt(AlistConstant.projectorTraversalMode,
            defValue: defaults.traversalMode.index) ??
        defaults.traversalMode.index;
    final imageStaySeconds = SpUtil.getInt(
            AlistConstant.projectorImageStaySeconds,
            defValue: defaults.imageStaySeconds) ??
        defaults.imageStaySeconds;
    final videoStaySeconds = SpUtil.getInt(
            AlistConstant.projectorVideoStaySeconds,
            defValue: defaults.videoStaySeconds) ??
        defaults.videoStaySeconds;
    final audioStaySeconds = SpUtil.getInt(
            AlistConstant.projectorAudioStaySeconds,
            defValue: defaults.audioStaySeconds) ??
        defaults.audioStaySeconds;
    final preloadCount = SpUtil.getInt(AlistConstant.projectorPreloadCount,
            defValue: defaults.preloadCount) ??
        defaults.preloadCount;
    final videoStayInfinite = SpUtil.getBool(
            AlistConstant.projectorVideoStayInfinite,
            defValue: defaults.videoStayInfinite) ??
        defaults.videoStayInfinite;
    final audioStayInfinite = SpUtil.getBool(
            AlistConstant.projectorAudioStayInfinite,
            defValue: defaults.audioStayInfinite) ??
        defaults.audioStayInfinite;

    final normalizedModeIndex =
        modeIndex.clamp(0, ProjectorTraversalMode.values.length - 1).toInt();

    return ProjectorConfig(
      traversalMode: ProjectorTraversalMode.values[normalizedModeIndex],
      imageStaySeconds: imageStaySeconds > 0
          ? imageStaySeconds
          : const ProjectorConfig.defaults().imageStaySeconds,
      videoStaySeconds: videoStaySeconds > 0
          ? videoStaySeconds
          : const ProjectorConfig.defaults().videoStaySeconds,
      audioStaySeconds: audioStaySeconds > 0
          ? audioStaySeconds
          : const ProjectorConfig.defaults().audioStaySeconds,
      preloadCount: ProjectorConfig._normalizePreloadCount(preloadCount),
      videoStayInfinite: videoStayInfinite,
      audioStayInfinite: audioStayInfinite,
    );
  }

  static Future<void> save(ProjectorConfig config) async {
    await SpUtil.putInt(
        AlistConstant.projectorTraversalMode, config.traversalMode.index);
    await SpUtil.putInt(
        AlistConstant.projectorImageStaySeconds, config.imageStaySeconds);
    await SpUtil.putInt(
        AlistConstant.projectorVideoStaySeconds, config.videoStaySeconds);
    await SpUtil.putInt(
        AlistConstant.projectorAudioStaySeconds, config.audioStaySeconds);
    await SpUtil.putInt(AlistConstant.projectorPreloadCount,
        ProjectorConfig._normalizePreloadCount(config.preloadCount));
    await SpUtil.putBool(
        AlistConstant.projectorVideoStayInfinite, config.videoStayInfinite);
    await SpUtil.putBool(
        AlistConstant.projectorAudioStayInfinite, config.audioStayInfinite);
  }
}
