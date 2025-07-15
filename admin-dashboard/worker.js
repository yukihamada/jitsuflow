const htmlContent = `<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JitsuFlow 管理ダッシュボード</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        .stat-card {
            transition: transform 0.2s;
        }
        .stat-card:hover {
            transform: translateY(-5px);
        }
        .qr-container {
            background: white;
            padding: 1rem;
            border-radius: 0.5rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .loading {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid rgba(255,255,255,.3);
            border-radius: 50%;
            border-top-color: #fff;
            animation: spin 1s ease-in-out infinite;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.5);
        }
        .modal.active {
            display: flex;
            align-items: center;
            justify-content: center;
        }
    </style>
</head>
<body class="bg-gray-100">
    <div class="min-h-screen flex items-center justify-center">
        <div class="bg-white rounded-lg shadow-lg p-8 max-w-md w-full">
            <div class="text-center">
                <div class="bg-purple-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                    <i class="fas fa-tools text-purple-600 text-2xl"></i>
                </div>
                <h1 class="text-2xl font-bold text-gray-800 mb-2">JitsuFlow 管理ダッシュボード</h1>
                <p class="text-gray-600 mb-6">システムメンテナンス中</p>
                <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
                    <div class="flex items-center">
                        <i class="fas fa-info-circle text-blue-600 mr-2"></i>
                        <span class="text-blue-800 text-sm">
                            現在、管理ダッシュボードのセットアップを完了しています。<br>
                            しばらくお待ちください。
                        </span>
                    </div>
                </div>
                <div class="text-sm text-gray-500">
                    <p>Admin Dashboard Setup</p>
                    <p class="mt-2">
                        <span class="inline-block w-2 h-2 bg-green-400 rounded-full mr-2"></span>
                        Custom Domain: ✓ Configured
                    </p>
                    <p class="mt-1">
                        <span class="inline-block w-2 h-2 bg-yellow-400 rounded-full mr-2"></span>
                        Static Assets: ⚠ In Progress
                    </p>
                </div>
            </div>
        </div>
    </div>
</body>
</html>`;

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    try {
      // 簡易的な認証チェック（本番環境では適切な認証を実装）
      const authHeader = request.headers.get('Authorization');
      if (!authHeader && url.pathname !== '/login') {
        // 認証が必要なページへのアクセス時は、実際の実装では認証ページへリダイレクト
        // return Response.redirect(url.origin + '/login', 302);
      }
      
      // パスの処理
      let pathname = url.pathname;
      if (pathname === '/') {
        pathname = '/index.html';
      }
      
      // 静的ファイルの取得
      if (env.ASSETS) {
        const asset = await env.ASSETS.fetch(request);
        if (asset && asset.status !== 404) {
          return asset;
        }
      }
      
      // Fallback: serve the maintenance page
      return new Response(htmlContent, {
        headers: { 'Content-Type': 'text/html' }
      });
      
    } catch (error) {
      return new Response('Internal Server Error: ' + error.message, { status: 500 });
    }
  }
};