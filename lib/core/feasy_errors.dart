String feasySwitchErrorToast(Object error) {
  if (error is UnsupportedError) {
    return 'Feasy 仅手机可用';
  }
  return 'Feasy 初始化失败: $error';
}
