# JiuFlow App Icon Design Guide

## 概要 / Overview

JiuFlow は「ブラジリアン柔術の練習・道場運営を最も効率的に行える唯一無二のプラットフォーム」。
アイコンはその世界観を一目で伝える顔であり、本ドキュメントはデザイナー・開発者が
再現可能な仕様を網羅します。

---

## 1. ブランドアイデンティティ / Brand Identity

### 1.1 ブランドキーワード
- **強さ** — 柔術の技術・精神を体現
- **流れ** — "Flow" の名の通り、技の連鎖とリズム
- **洗練** — プロフェッショナルなスポーツアプリとしての信頼感
- **国際性** — 日本の柔道ルーツ × ブラジルのBJJ文化

### 1.2 カラーパレット

| 役割 | 色名 | HEX | RGB | 用途 |
|------|------|-----|-----|------|
| プライマリ | Deep Blue | `#1E3A8A` | 30, 58, 138 | 背景・帯の表現 |
| サブ | Blue | `#1E40AF` | 30, 64, 175 | グラデーション・補助色 |
| アクセント | Gold | `#F59E0B` | 245, 158, 11 | ハイライト・帯の金色 |
| アクセント2 | Amber | `#D97706` | 217, 119, 6 | 帯の影・立体感 |
| テキスト | White | `#FFFFFF` | 255, 255, 255 | ロゴ文字 |
| 影 | Dark Blue | `#0F172A` | 15, 23, 42 | 奥行き・ドロップシャドウ |

### 1.3 タイポグラフィ
- **ロゴ文字**: `JF`（JiuFlow の頭文字）
- **推奨フォント**: Bebas Neue / Montserrat ExtraBold / SF Pro Rounded Bold
- **代替フォント**: Arial Black, Impact（SVG/フォールバック用）
- 文字は必ず**ベクター化**してアウトライン変換すること

---

## 2. テクニカル仕様 / Technical Specifications

### 2.1 マスターファイル

| 項目 | 仕様 |
|------|------|
| サイズ | **1024 × 1024 px** |
| フォーマット | **PNG-32**（アルファチャンネルあり）または PNG-24 |
| カラースペース | **sRGB** |
| 解像度 | 72 dpi（ピクセル等倍）|
| ファイル名 | `app_icon.png` |
| 保存先 | `assets/icon/app_icon.png` |

> **注意**: iOS は自動でアイコンを角丸処理するため、元ファイルを角丸にする必要はない。
> ただし、Android のアダプティブアイコンでは**安全領域**が重要（後述）。

### 2.2 iOS 必要サイズ一覧

Flutter の `flutter_launcher_icons` が自動生成するが、参考として記載:

| 用途 | サイズ |
|------|--------|
| App Store | 1024 × 1024 |
| iPhone Notification (3x) | 60 × 60 |
| iPhone Settings (3x) | 87 × 87 |
| iPhone Spotlight (3x) | 120 × 120 |
| iPhone App (3x) | 180 × 180 |
| iPad Pro App (2x) | 167 × 167 |
| iPad App (2x) | 152 × 152 |

### 2.3 Android 必要サイズ一覧

| 密度 | サイズ | 用途 |
|------|--------|------|
| mdpi | 48 × 48 | 基準 |
| hdpi | 72 × 72 | |
| xhdpi | 96 × 96 | |
| xxhdpi | 144 × 144 | |
| xxxhdpi | 192 × 192 | |
| Web / Play Store | 512 × 512 | |

### 2.4 Android アダプティブアイコン（Adaptive Icon）

Android 8.0+ ではフォアグラウンド・バックグラウンドを分離して生成する:

```
アイコン全体 108 × 108 dp
  └── 安全領域: 72 × 72 dp（中央）← ここにメインモチーフを収める
  └── 余白 (各辺 18 dp) は OS により切り取られる可能性あり
```

`pubspec.yaml` での設定例:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#1E3A8A"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
  web:
    generate: true
    image_path: "assets/icon/app_icon.png"
    background_color: "#1E3A8A"
    theme_color: "#1E40AF"
  windows:
    generate: true
    image_path: "assets/icon/app_icon.png"
    icon_size: 48
```

---

## 3. デザインコンセプト / Design Concept

### 3.1 ビジュアルモチーフ（推奨案）

#### A案: 帯（Belt）モチーフ ← **現採用**
- 青い正方形背景（角丸なし）
- 中央を横切る帯（金色〜アンバーのグラデーション）
- 帯の上に「JF」ロゴ文字（白・太字）
- 帯の結び目のニュアンスを右中央に小さな形で表現

#### B案: 人型シルエット（Grappling Silhouette）
- ガードポジションまたはアームバーのシルエット
- 単色または2トーンで表現（詳細より形で語る）
- 「JF」をシルエットの周囲または下部に配置

#### C案: 抽象 JF + 帯グラフィック
- 「JF」の文字自体をデザイン化（帯が文字を構成する）
- 流れるような筆致でブラジリアン柔術の「流れ」を表現

### 3.2 コンポジション ガイドライン

```
┌──────────────────────────────┐
│         (余白 10%)           │
│  ┌────────────────────────┐  │
│  │                        │  │
│  │    メインモチーフ       │  │
│  │    (中央 80% 領域)      │  │
│  │                        │  │
│  └────────────────────────┘  │
│         (余白 10%)           │
└──────────────────────────────┘
```

- メインモチーフは全体の **60〜70%** に収める
- 背景は単色またはラジアルグラデーション（中心明→外周暗）
- 小さいサイズ（48px）でも視認できるシンプルさを保つ

### 3.3 Do's and Don'ts

**✅ Do**
- 高コントラストで小サイズでも識別可能
- 金色（アクセント）は面積比 20〜30% に抑える
- 角は Flutter/iOS により自動で処理されるのでマスターは正方形のまま

**❌ Don't**
- 細い線（1px 以下相当）の多用（縮小時につぶれる）
- 4色以上のカラー使用（シンプルさを損なう）
- テキストを小さく入れすぎる（App Icon に文字詳細は不要）
- App Store のスクリーンショットと混同するような写真系素材の使用
- 他社商標・著名アスリートの肖像の無断使用

---

## 4. SVGソースファイル / SVG Source

現在の `app_icon.svg` は実装上の参照用プレースホルダー。
最終デザインは Figma / Illustrator / Sketch で作成し、1024px PNG でエクスポートすること。

現SVGの構造メモ:

```xml
<!-- 背景: 青い円 -->
<circle cx="512" cy="512" r="512" fill="#1E40AF"/>

<!-- 帯モチーフ: ベジェ曲線 -->
<path d="M 256 400 Q 512 300 768 400 ..." fill="#F59E0B"/>

<!-- ロゴ文字: JF -->
<text x="512" y="550" font-size="280" font-weight="bold" fill="white">JF</text>
```

> **改善ポイント**: 円形背景 → 正方形背景に変更推奨（iOS が角丸処理するため）。
> また、フォントを `include` または SVG フォントでアウトライン化すること。

---

## 5. アイコン更新手順 / How to Update

### Step 1: デザインファイルを用意

1. Figma / Illustrator で 1024×1024px のアートボードを作成
2. 上記のカラーパレット・コンポジションガイドに従いデザイン
3. **1024×1024 PNG** でエクスポート（透過なし、背景色あり）
4. `assets/icon/app_icon.png` に保存

### Step 2: アダプティブアイコン用フォアグラウンドを作成（Android）

1. 同様に 1024×1024px でメインモチーフのみ（透過背景）を作成
2. `assets/icon/app_icon_foreground.png` に保存

### Step 3: アイコン自動生成

```bash
# プロジェクトルートで実行
cd /Users/yuki/workspace/bjj/jitsuflow
flutter pub get
flutter pub run flutter_launcher_icons
```

生成先:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- `android/app/src/main/res/mipmap-*/`
- `web/icons/`

### Step 4: 確認

```bash
# 物理 iPhone に直接デプロイして確認
flutter run -d 00008140-0005453411E0801C --device-timeout 120
```

ホーム画面・Spotlight 検索・設定アプリでアイコンを目視確認すること。

---

## 6. 参考リソース / References

### App Store ガイドライン
- [Apple Human Interface Guidelines — App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Google Material Design — Product Icons](https://m3.material.io/styles/icons/overview)

### デザインツール
- **Figma** ([figma.com](https://figma.com)) — 推奨、リアルタイムコラボ
- **Sketch** — Mac専用、App Icon テンプレートが豊富
- **Affinity Designer** — 買い切り、高コスパ

### SVG → PNG 変換
```bash
# ImageMagick (Homebrew)
brew install imagemagick
convert -background none -size 1024x1024 app_icon.svg app_icon.png

# Inkscape (コマンドライン)
inkscape app_icon.svg --export-png=app_icon.png --export-width=1024
```

### アイコンプレビューツール
- **AppIconMaker** ([appiconmaker.co](https://appiconmaker.co)) — オンラインで全サイズ一括生成
- **MakeAppIcon** ([makeappicon.com](https://makeappicon.com)) — iOS/Android 両対応

---

## 7. チェックリスト / Pre-submission Checklist

デザイン完成後、App Store / Play Store 提出前に確認:

- [ ] 1024×1024 PNG マスターファイルが `assets/icon/app_icon.png` に存在する
- [ ] 透過部分がない（iOS App Store は透過アイコンを拒否する）
- [ ] 角丸処理されていない（OS が処理する）
- [ ] 他社ロゴ・著作権素材が含まれていない
- [ ] `flutter pub run flutter_launcher_icons` 実行済み
- [ ] 物理 iPhone の設定アプリ・ホーム画面・Spotlight でアイコンを目視確認済み
- [ ] iOS App Store Connect でプレビュー確認済み（1024px 画像アップロード）
- [ ] Android Google Play Console でアイコンプレビュー確認済み

---

*最終更新: 2026-04-13*  
*対象アプリ: JiuFlow (bundle: app.jitsuflow.jitsuflow)*
