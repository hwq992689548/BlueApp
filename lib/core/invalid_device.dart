/// BlueApp：判定扫描结果是否「无效」。
abstract final class InvalidDevice {
  /// 私有构造。
  InvalidDevice._();

  /// 无名称（广播名与平台名皆空）或不可连接视为无效。
  static bool isInvalid({required String advName, required String platformName, required bool connectable}) {
    final noName = advName.trim().isEmpty && platformName.trim().isEmpty;
    return noName || !connectable;
  }
}
