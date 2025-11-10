enum SnapMode { bar, beat, grid, free }

extension SnapModeLabel on SnapMode {
  String get label {
    switch (this) {
      case SnapMode.bar:
        return '小節';
      case SnapMode.beat:
        return '拍';
      case SnapMode.grid:
        return 'グリッド';
      case SnapMode.free:
        return 'フリー';
    }
  }

  String get shortLabel {
    switch (this) {
      case SnapMode.bar:
        return 'BAR';
      case SnapMode.beat:
        return 'BEAT';
      case SnapMode.grid:
        return 'GRID';
      case SnapMode.free:
        return 'FREE';
    }
  }
}
