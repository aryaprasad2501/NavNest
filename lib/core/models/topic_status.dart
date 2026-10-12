import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/nest_badge.dart';

enum TopicStatus {
  notStarted,
  inProgress,
  studyingNow,
  completed,
  needsRevision,
  needsRestudy;

  String get code {
    switch (this) {
      case TopicStatus.notStarted:
        return 'NOT_STARTED';
      case TopicStatus.inProgress:
        return 'IN_PROGRESS';
      case TopicStatus.studyingNow:
        return 'STUDYING_NOW';
      case TopicStatus.completed:
        return 'COMPLETED';
      case TopicStatus.needsRevision:
        return 'NEEDS_REVISION';
      case TopicStatus.needsRestudy:
        return 'NEEDS_RESTUDY';
    }
  }

  static TopicStatus fromCode(String? code) {
    switch (code) {
      case 'IN_PROGRESS':
        return TopicStatus.inProgress;
      case 'STUDYING_NOW':
        return TopicStatus.studyingNow;
      case 'COMPLETED':
        return TopicStatus.completed;
      case 'NEEDS_REVISION':
        return TopicStatus.needsRevision;
      case 'NEEDS_RESTUDY':
        return TopicStatus.needsRestudy;
      case 'NOT_STARTED':
      default:
        return TopicStatus.notStarted;
    }
  }

  String get displayName {
    switch (this) {
      case TopicStatus.notStarted:
        return 'Not Started';
      case TopicStatus.inProgress:
        return 'In Progress';
      case TopicStatus.studyingNow:
        return 'Studying Now';
      case TopicStatus.completed:
        return 'Completed';
      case TopicStatus.needsRevision:
        return 'Needs Revision';
      case TopicStatus.needsRestudy:
        return 'Needs Restudy';
    }
  }

  NestBadgeVariant get badgeVariant {
    switch (this) {
      case TopicStatus.notStarted:
        return NestBadgeVariant.neutral;
      case TopicStatus.inProgress:
        return NestBadgeVariant.amber;
      case TopicStatus.studyingNow:
        return NestBadgeVariant.safeGreen;
      case TopicStatus.completed:
        return NestBadgeVariant.forest;
      case TopicStatus.needsRevision:
        return NestBadgeVariant.lavender;
      case TopicStatus.needsRestudy:
        return NestBadgeVariant.coral;
    }
  }

  Color get color {
    switch (this) {
      case TopicStatus.notStarted:
        return AppColors.textMuted;
      case TopicStatus.inProgress:
        return AppColors.amberHoney;
      case TopicStatus.studyingNow:
        return AppColors.safeGreen;
      case TopicStatus.completed:
        return AppColors.deepForest;
      case TopicStatus.needsRevision:
        return AppColors.revisionPurple;
      case TopicStatus.needsRestudy:
        return AppColors.restudyCoral;
    }
  }

  /// Weight contributed to chapter completion (0.0 to 1.0)
  double get completionWeight {
    switch (this) {
      case TopicStatus.completed:
        return 1.0;
      case TopicStatus.needsRevision:
        return 0.85; // Studied but marked for review
      case TopicStatus.inProgress:
      case TopicStatus.studyingNow:
        return 0.30;
      case TopicStatus.needsRestudy:
        return 0.20;
      case TopicStatus.notStarted:
        return 0.0;
    }
  }
}
