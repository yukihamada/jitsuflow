import 'dart:io';
import 'dart:math' as math;

void main() async {
  print('🎨 JitsuFlow プロフェッショナルアイコン生成');
  
  // SVGコンテンツを生成
  final svgContent = '''
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <!-- 背景グラデーション -->
  <defs>
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1A1A2E;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#16213E;stop-opacity:1" />
    </linearGradient>
    
    <!-- 帯のグラデーション -->
    <linearGradient id="beltGradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#E94560;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#C13651;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#E94560;stop-opacity:1" />
    </linearGradient>
    
    <!-- ドロップシャドウ -->
    <filter id="shadow">
      <feDropShadow dx="0" dy="4" stdDeviation="8" flood-opacity="0.3"/>
    </filter>
  </defs>
  
  <!-- 背景 -->
  <rect width="1024" height="1024" fill="url(#bgGradient)"/>
  
  <!-- 装飾的な円（背景） -->
  <circle cx="512" cy="512" r="450" fill="none" stroke="#E94560" stroke-width="2" opacity="0.1"/>
  <circle cx="512" cy="512" r="400" fill="none" stroke="#E94560" stroke-width="1" opacity="0.15"/>
  
  <!-- 中央の帯 -->
  <rect x="150" y="412" width="724" height="200" rx="20" fill="url(#beltGradient)" filter="url(#shadow)"/>
  
  <!-- 帯の装飾線 -->
  <rect x="150" y="432" width="724" height="5" fill="#FFFFFF" opacity="0.3"/>
  <rect x="150" y="587" width="724" height="5" fill="#000000" opacity="0.2"/>
  
  <!-- JITSUテキスト -->
  <text x="512" y="350" font-family="Arial Black, sans-serif" font-size="140" font-weight="900" 
        text-anchor="middle" fill="#FFFFFF" filter="url(#shadow)">JITSU</text>
  
  <!-- FLOWテキスト -->
  <text x="512" y="720" font-family="Arial Black, sans-serif" font-size="140" font-weight="900" 
        text-anchor="middle" fill="#FFFFFF" filter="url(#shadow)">FLOW</text>
  
  <!-- 中央の柔術文字 -->
  <text x="512" y="540" font-family="Hiragino Sans, Arial Unicode MS, sans-serif" font-size="100" 
        font-weight="bold" text-anchor="middle" fill="#FFFFFF" opacity="0.9">柔術</text>
  
  <!-- 装飾的な要素 -->
  <path d="M 350 512 Q 380 480, 410 512" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.5"/>
  <path d="M 614 512 Q 644 480, 674 512" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.5"/>
</svg>
''';
  
  // SVGファイルを保存
  final svgFile = File('/tmp/jitsuflow_icon.svg');
  await svgFile.writeAsString(svgContent);
  
  print('✅ SVGアイコンを生成しました');
  print('📍 保存先: ${svgFile.path}');
  
  // 変換コマンドを出力
  print('\n🔄 PNGに変換するには以下のコマンドを実行:');
  print('magick /tmp/jitsuflow_icon.svg -resize 1024x1024 /Users/yuki/jitsuflow/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png');
}