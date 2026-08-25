import 'package:flutter/material.dart';

/// 调试宝布局密度样式（手机 / 宽屏各一套）。
///
/// 字段顺序：按页面从上到下、同行从左到右。
@immutable
class BlueLayoutStyles {
  /// 构造。
  const BlueLayoutStyles({
    // —— 扫描页 · 顶栏 / 筛选 ——
    required this.scanToolbarPadding,
    required this.scanToolbarTitleGap,
    required this.scanToolbarFieldGap,
    required this.scanFilterOuterPadding,
    required this.scanFilterInnerPadding,
    required this.scanFilterTitleGap,
    required this.scanFilterDescGap,
    required this.scanKeywordFontSize,
    required this.scanSearchIconSize,
    required this.scanKeywordHint,
    required this.scanFilterFieldGap,
    required this.scanCheckboxSize,
    required this.scanCheckboxGap,
    required this.scanHideInvalidLabel,
    // —— 扫描页 · 列表 ——
    required this.scanListPadding,
    required this.scanListSeparator,
    required this.scanEmptyMessage,
    // —— 扫描页 · 设备行 ——
    required this.scanTilePadding,
    required this.scanTileRadius,
    required this.scanTileNameFontSize,
    required this.scanTileNameToIdGap,
    required this.scanTileIdFontSize,
    required this.scanTileIdToMetaGap,
    required this.scanTileRssiBarsGap,
    required this.scanTileRssiFontSize,
    required this.scanTileRssiToStatusGap,
    required this.scanTileTrailingGap,
    // —— 设备页 · 顶部 · 未连接 ——
    required this.devicePlaceholderIconSize,
    required this.devicePlaceholderIconGap,
    // —— 设备页 · 顶部 · 已连接 ——
    required this.deviceTopWidePadding,
    required this.deviceTopOuterPadding,
    required this.deviceTopInnerPadding,
    required this.deviceTopTitleGap,
    required this.deviceRemoteIdFontSize,
    required this.deviceTopMetaGap,
    // —— 设备页 · 服务 ——
    required this.serviceSectionPadding,
    required this.serviceSectionHint,
    required this.serviceListPadding,
    required this.serviceCardRadius,
    required this.serviceCardGap,
    required this.serviceHeaderPadding,
    required this.serviceUuidFontSize,
    required this.serviceUuidMaxLines,
    required this.serviceExpandIconSize,
    // —— 设备页 · 特征 ——
    required this.characteristicTilePadding,
    required this.characteristicTileUuidFontSize,
    required this.characteristicUuidToChipsGap,
    required this.characteristicChipsCompact,
    required this.characteristicTileTrailingGap,
  });

  /// 手机窄屏。
  static const phone = BlueLayoutStyles(
    // —— 扫描页 · 顶栏 / 筛选 ——
    scanToolbarPadding: EdgeInsets.fromLTRB(16, 12, 16, 8),
    scanToolbarTitleGap: 8,
    scanToolbarFieldGap: 8,
    scanFilterOuterPadding: EdgeInsets.fromLTRB(16, 12, 16, 8),
    scanFilterInnerPadding: EdgeInsets.all(12),
    scanFilterTitleGap: 6,
    scanFilterDescGap: 12,
    scanKeywordFontSize: 14,
    scanSearchIconSize: 18,
    scanKeywordHint: '筛选名称 / MAC',
    scanFilterFieldGap: 4,
    scanCheckboxSize: 22,
    scanCheckboxGap: 8,
    scanHideInvalidLabel: '屏蔽无效（无名称 / 不可连接）',
    // —— 扫描页 · 列表 ——
    scanListPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
    scanListSeparator: 8,
    scanEmptyMessage: '未发现设备\n点右上角「扫描」',
    // —— 扫描页 · 设备行 ——
    scanTilePadding: EdgeInsets.fromLTRB(12, 12, 12, 12),
    scanTileRadius: 12,
    scanTileNameFontSize: 15,
    scanTileNameToIdGap: 4,
    scanTileIdFontSize: 11,
    scanTileIdToMetaGap: 6,
    scanTileRssiBarsGap: 8,
    scanTileRssiFontSize: 12,
    scanTileRssiToStatusGap: 10,
    scanTileTrailingGap: 8,
    // —— 设备页 · 顶部 · 未连接 ——
    devicePlaceholderIconSize: 36,
    devicePlaceholderIconGap: 12,
    // —— 设备页 · 顶部 · 已连接 ——
    deviceTopWidePadding: EdgeInsets.fromLTRB(16, 10, 12, 10),
    deviceTopOuterPadding: EdgeInsets.fromLTRB(16, 12, 16, 8),
    deviceTopInnerPadding: EdgeInsets.all(12),
    deviceTopTitleGap: 6,
    deviceRemoteIdFontSize: 11,
    deviceTopMetaGap: 10,
    // —— 设备页 · 服务 ——
    serviceSectionPadding: EdgeInsets.fromLTRB(16, 0, 16, 6),
    serviceSectionHint: '点特征打开读写',
    serviceListPadding: EdgeInsets.fromLTRB(16, 0, 16, 8),
    serviceCardRadius: 12,
    serviceCardGap: 8,
    serviceHeaderPadding: EdgeInsets.fromLTRB(12, 10, 12, 10),
    serviceUuidFontSize: 12,
    serviceUuidMaxLines: 2,
    serviceExpandIconSize: 24,
    // —— 设备页 · 特征 ——
    characteristicTilePadding: EdgeInsets.fromLTRB(14, 10, 12, 10),
    characteristicTileUuidFontSize: 11.5,
    characteristicUuidToChipsGap: 6,
    characteristicChipsCompact: true,
    characteristicTileTrailingGap: 6,
  );

  /// 宽屏三栏。
  static const wide = BlueLayoutStyles(
    // —— 扫描页 · 顶栏 / 筛选 ——
    scanToolbarPadding: EdgeInsets.fromLTRB(12, 10, 12, 10),
    scanToolbarTitleGap: 8,
    scanToolbarFieldGap: 8,
    scanFilterOuterPadding: EdgeInsets.zero,
    scanFilterInnerPadding: EdgeInsets.zero,
    scanFilterTitleGap: 6,
    scanFilterDescGap: 12,
    scanKeywordFontSize: 14,
    scanSearchIconSize: 20,
    scanKeywordHint: '名称 / MAC',
    scanFilterFieldGap: 8,
    scanCheckboxSize: 20,
    scanCheckboxGap: 6,
    scanHideInvalidLabel: '屏蔽无效',
    // —— 扫描页 · 列表 ——
    scanListPadding: EdgeInsets.fromLTRB(12, 12, 12, 12),
    scanListSeparator: 6,
    scanEmptyMessage: '未发现设备',
    // —— 扫描页 · 设备行 ——
    scanTilePadding: EdgeInsets.fromLTRB(12, 10, 12, 12),
    scanTileRadius: 8,
    scanTileNameFontSize: 14,
    scanTileNameToIdGap: 2,
    scanTileIdFontSize: 12,
    scanTileIdToMetaGap: 4,
    scanTileRssiBarsGap: 6,
    scanTileRssiFontSize: 12,
    scanTileRssiToStatusGap: 8,
    scanTileTrailingGap: 8,
    // —— 设备页 · 顶部 · 未连接 ——
    devicePlaceholderIconSize: 48,
    devicePlaceholderIconGap: 12,
    // —— 设备页 · 顶部 · 已连接 ——
    deviceTopWidePadding: EdgeInsets.fromLTRB(12, 10, 12, 10),
    deviceTopOuterPadding: EdgeInsets.zero,
    deviceTopInnerPadding: EdgeInsets.zero,
    deviceTopTitleGap: 6,
    deviceRemoteIdFontSize: 11,
    deviceTopMetaGap: 10,
    // —— 设备页 · 服务 ——
    serviceSectionPadding: EdgeInsets.fromLTRB(12, 12, 12, 8),
    serviceSectionHint: '点选特征',
    serviceListPadding: EdgeInsets.fromLTRB(12, 0, 12, 12),
    serviceCardRadius: 8,
    serviceCardGap: 8,
    serviceHeaderPadding: EdgeInsets.fromLTRB(12, 10, 12, 10),
    serviceUuidFontSize: 11,
    serviceUuidMaxLines: 1,
    serviceExpandIconSize: 20,
    // —— 设备页 · 特征 ——
    characteristicTilePadding: EdgeInsets.fromLTRB(12, 10, 12, 10),
    characteristicTileUuidFontSize: 11,
    characteristicUuidToChipsGap: 6,
    characteristicChipsCompact: true,
    characteristicTileTrailingGap: 6,
  );

  // —— 扫描页 · 顶栏 / 筛选 ——

  /// 宽屏 DEVICES 顶栏内边距。
  final EdgeInsets scanToolbarPadding;

  /// 顶栏标题与计数间距。
  final double scanToolbarTitleGap;

  /// 顶栏标题行与输入框间距。
  final double scanToolbarFieldGap;

  /// 手机筛选卡外层内边距。
  final EdgeInsets scanFilterOuterPadding;

  /// 手机筛选卡内层内边距。
  final EdgeInsets scanFilterInnerPadding;

  /// 筛选卡标题下间距。
  final double scanFilterTitleGap;

  /// 筛选卡说明下间距。
  final double scanFilterDescGap;

  /// 筛选输入框字号。
  final double scanKeywordFontSize;

  /// 筛选搜索图标尺寸。
  final double scanSearchIconSize;

  /// 筛选输入框 hint。
  final String scanKeywordHint;

  /// 筛选输入框与勾选行间距。
  final double scanFilterFieldGap;

  /// 屏蔽无效勾选框边长。
  final double scanCheckboxSize;

  /// 勾选框与文案间距。
  final double scanCheckboxGap;

  /// 屏蔽无效文案。
  final String scanHideInvalidLabel;

  // —— 扫描页 · 列表 ——

  /// 扫描列表内边距。
  final EdgeInsets scanListPadding;

  /// 扫描列表项间距。
  final double scanListSeparator;

  /// 扫描空态文案。
  final String scanEmptyMessage;

  // —— 扫描页 · 设备行 ——

  /// 设备行内边距。
  final EdgeInsets scanTilePadding;

  /// 设备行圆角。
  final double scanTileRadius;

  /// 设备名字号。
  final double scanTileNameFontSize;

  /// 设备名与 remoteId 间距。
  final double scanTileNameToIdGap;

  /// remoteId 字号。
  final double scanTileIdFontSize;

  /// remoteId 与 meta 行间距。
  final double scanTileIdToMetaGap;

  /// RSSI 条与数值间距。
  final double scanTileRssiBarsGap;

  /// RSSI 字号。
  final double scanTileRssiFontSize;

  /// RSSI 与状态标签间距。
  final double scanTileRssiToStatusGap;

  /// 左侧信息与右侧操作间距。
  final double scanTileTrailingGap;

  // —— 设备页 · 顶部 · 未连接 ——

  /// 未连接占位图标尺寸。
  final double devicePlaceholderIconSize;

  /// 未连接占位图标与文案间距。
  final double devicePlaceholderIconGap;

  // —— 设备页 · 顶部 · 已连接 ——

  /// 宽屏已连接顶栏内边距。
  final EdgeInsets deviceTopWidePadding;

  /// 手机已连接信息卡外层内边距。
  final EdgeInsets deviceTopOuterPadding;

  /// 手机已连接信息卡内层内边距。
  final EdgeInsets deviceTopInnerPadding;

  /// CONNECTED 标题下间距。
  final double deviceTopTitleGap;

  /// 顶部 remoteId 字号。
  final double deviceRemoteIdFontSize;

  /// 名称区与 meta 行间距。
  final double deviceTopMetaGap;

  // —— 设备页 · 服务 ——

  /// SERVICES 标题区内边距。
  final EdgeInsets serviceSectionPadding;

  /// SERVICES 右侧提示。
  final String serviceSectionHint;

  /// 服务列表内边距。
  final EdgeInsets serviceListPadding;

  /// Service 卡片圆角。
  final double serviceCardRadius;

  /// Service 卡片底间距。
  final double serviceCardGap;

  /// Service 头内边距。
  final EdgeInsets serviceHeaderPadding;

  /// Service UUID 字号。
  final double serviceUuidFontSize;

  /// Service UUID 最大行数。
  final int serviceUuidMaxLines;

  /// 展开箭头尺寸。
  final double serviceExpandIconSize;

  // —— 设备页 · 特征 ——

  /// 特征行内边距。
  final EdgeInsets characteristicTilePadding;

  /// 特征 UUID 字号。
  final double characteristicTileUuidFontSize;

  /// UUID 与属性标签间距。
  final double characteristicUuidToChipsGap;

  /// 属性标签是否紧凑。
  final bool characteristicChipsCompact;

  /// 特征行内容与右侧图标间距。
  final double characteristicTileTrailingGap;
}
