export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // パスの処理
    let pathname = url.pathname;
    if (pathname === '/') {
      pathname = '/index.html';
    }
    
    // 静的ファイルの取得
    const asset = await env.ASSETS.fetch(request);
    if (asset) {
      return asset;
    }
    
    // 404ページ
    return new Response('Not Found', { status: 404 });
  }
};