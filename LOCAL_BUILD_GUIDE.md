# ローカルビルド・動作確認ガイド

## 1. 必要な環境のセットアップ

### 1.1 Flutter SDKのインストール

#### Windowsの場合
1. Flutter SDKをダウンロード
   - https://flutter.dev/docs/get-started/install/windows
   - ZIPファイルをダウンロードして解凍（例: `C:\src\flutter`）

2. 環境変数の設定
   - `PATH`に`C:\src\flutter\bin`を追加

3. 確認
   ```bash
   flutter doctor
   ```

#### Macの場合
1. Flutter SDKをダウンロード
   - https://flutter.dev/docs/get-started/install/macos
   - ZIPファイルをダウンロードして解凍（例: `~/development/flutter`）

2. 環境変数の設定（`.zshrc`または`.bash_profile`に追加）
   ```bash
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```

3. 確認
   ```bash
   flutter doctor
   ```

#### Linuxの場合
1. Flutter SDKをダウンロード
   - https://flutter.dev/docs/get-started/install/linux
   - ZIPファイルをダウンロードして解凍（例: `~/development/flutter`）

2. 環境変数の設定（`.bashrc`に追加）
   ```bash
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```

3. 確認
   ```bash
   flutter doctor
   ```

### 1.2 Android Studioのインストール

1. Android Studioをダウンロード・インストール
   - https://developer.android.com/studio

2. Android SDKのセットアップ
   - Android Studioを起動
   - 「More Actions」→「SDK Manager」
   - 「SDK Platforms」タブで「Android 13.0 (Tiramisu)」以上をインストール
   - 「SDK Tools」タブで以下をインストール：
     - Android SDK Build-Tools
     - Android SDK Platform-Tools
     - Android SDK Command-line Tools

3. 環境変数の設定
   - Windows: `ANDROID_HOME` = `C:\Users\<ユーザー名>\AppData\Local\Android\Sdk`
   - Mac/Linux: `ANDROID_HOME` = `~/Library/Android/sdk` (Mac) または `~/Android/Sdk` (Linux)
   - `PATH`に`$ANDROID_HOME/platform-tools`を追加

### 1.3 Flutter Doctorの確認

```bash
flutter doctor
```

以下がすべてチェックされていることを確認：
- ✅ Flutter (Channel stable)
- ✅ Android toolchain
- ✅ Android Studio
- ✅ VS Code (オプション)

## 2. プロジェクトのセットアップ

### 2.1 リポジトリのクローン

```bash
git clone https://github.com/nmdsuuuj/intervention-engine.git
cd intervention-engine
```

### 2.2 依存関係のインストール

```bash
flutter pub get
```

### 2.3 現在のブランチの確認

```bash
git branch
# fix/agp-version-explicit ブランチで作業中
```

## 3. 動作確認方法

### 3.1 エミュレーターでの実行（推奨）

#### エミュレーターの起動

1. Android Studioを起動
2. 「More Actions」→「Virtual Device Manager」
3. 「Create Device」をクリック
4. デバイスを選択（例: Pixel 5）
5. システムイメージを選択（例: Android 13.0）
6. 「Finish」をクリック
7. エミュレーターを起動

#### アプリの実行

```bash
# 接続されているデバイスを確認
flutter devices

# アプリを実行
flutter run

# リリースモードで実行
flutter run --release
```

### 3.2 実機での実行

#### Android実機の準備

1. 開発者オプションを有効化
   - 設定 → デバイス情報 → ビルド番号を7回タップ

2. USBデバッグを有効化
   - 設定 → 開発者オプション → USBデバッグをON

3. USBケーブルでPCに接続

4. 確認
   ```bash
   flutter devices
   # 実機が表示されることを確認
   ```

#### アプリの実行

```bash
flutter run
```

### 3.3 APKのビルド

#### Debug APK（開発用）

```bash
flutter build apk --debug
```

出力先: `build/app/outputs/flutter-apk/app-debug.apk`

#### Release APK（リリース用）

```bash
flutter build apk --release
```

出力先: `build/app/outputs/flutter-apk/app-release.apk`

#### APKのインストール

```bash
# 実機に接続している場合
adb install build/app/outputs/flutter-apk/app-release.apk

# または、APKファイルを実機に転送して手動インストール
```

## 4. トラブルシューティング

### 4.1 Gradleビルドエラー

```bash
# Gradleキャッシュをクリア
cd android
./gradlew clean
cd ..

# Flutterのクリーンビルド
flutter clean
flutter pub get
flutter build apk --release
```

### 4.2 依存関係のエラー

```bash
# pubspec.lockを削除して再取得
rm pubspec.lock
flutter pub get
```

### 4.3 エミュレーターが起動しない

- Android Studioの「Virtual Device Manager」でエミュレーターを削除して再作成
- AVDの設定で「Graphics」を「Hardware - GLES 2.0」に変更

### 4.4 実機が認識されない

```bash
# ADBサーバーを再起動
adb kill-server
adb start-server
adb devices
```

## 5. 開発ワークフロー

### 5.1 機能ブランチでの作業

```bash
# 新しい機能ブランチを作成
git checkout -b feature/your-feature-name

# 変更をコミット
git add .
git commit -m "feat: Add your feature"

# リモートにプッシュ
git push origin feature/your-feature-name
```

### 5.2 ホットリロード（開発中）

アプリ実行中に：
- `r`キー: ホットリロード
- `R`キー: ホットリスタート
- `q`キー: 終了

### 5.3 デバッグ

```bash
# デバッグモードで実行
flutter run --debug

# ログを確認
flutter logs
```

## 6. 現在のブランチ状態

- **現在のブランチ**: `fix/agp-version-explicit`
- **mainブランチ**: 保護済み（直接プッシュしない）
- **作業方針**: 機能ブランチで作業 → プルリクエスト → マージ

## 7. 次のステップ

1. ローカル環境をセットアップ
2. エミュレーターまたは実機で動作確認
3. 問題があれば機能ブランチで修正
4. プルリクエストを作成してマージ
