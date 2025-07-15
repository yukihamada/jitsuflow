export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // 静的ファイルのMIMEタイプマッピング
    const mimeTypes = {
      'html': 'text/html',
      'css': 'text/css',
      'js': 'application/javascript',
      'json': 'application/json',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'svg': 'image/svg+xml',
      'ico': 'image/x-icon'
    };
    
    // パスの処理
    let pathname = url.pathname;
    if (pathname === '/') {
      pathname = '/index.html';
    }
    
    // アセットから静的ファイルを取得
    const asset = env.ASSETS.fetch(request);
    if (asset) {
      return asset;
    }
    
    // 404ページ
    return new Response('Not Found', { status: 404 });
  }
};