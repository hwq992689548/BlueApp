import 'invalid_device.dart';

/// BlueApp：扫描列表关键词与屏蔽无效过滤。
abstract final class ScanFilter {
  /// 私有构造。
  ScanFilter._();

  /// 是否应展示该条扫描结果。
  static bool shouldShow({
    required String keyword,
    required bool hideInvalid,
    required String advName,
    required String platformName,
    required String remoteId,
    required bool connectable,
  }) {
    if (hideInvalid && InvalidDevice.isInvalid(advName: advName, platformName: platformName, connectable: connectable)) {
      return false;
    }
    return matchesKeyword(keyword: keyword, advName: advName, platformName: platformName, remoteId: remoteId);
  }

  /// 关键词包含匹配（空关键词视为全部通过）。
  static bool matchesKeyword({required String keyword, required String advName, required String platformName, required String remoteId}) {
    final trimmed = keyword.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return true;
    }
    return advName.toLowerCase().contains(trimmed) || platformName.toLowerCase().contains(trimmed) || remoteId.toLowerCase().contains(trimmed);
  }
}
