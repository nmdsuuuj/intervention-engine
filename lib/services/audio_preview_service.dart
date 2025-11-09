import '../models/note.dart';

/// 将来的にMIDI/AUDIOエンジンと接続される「試聴」制御のスタブ。
class AudioPreviewService {
  bool _isLooping = false;

  bool get isLooping => _isLooping;

  /// 変異後のノートをループ再生する。
  /// （現時点ではスタブ実装のため、状態フラグのみ更新）
  Future<void> playLoop(List<Note> notes) async {
    _isLooping = true;
    // TODO: 実際のオーディオエンジンとの接続を実装
  }

  void stop() {
    _isLooping = false;
  }
}
