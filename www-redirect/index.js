export default {
  async fetch(request) {
    const url = new URL(request.url);
    
    // www.jitsuflow.app を jitsuflow.app にリダイレクト
    if (url.hostname === 'www.jitsuflow.app') {
      // HTTPSを維持し、パスとクエリパラメータを保持
      const redirectUrl = `https://jitsuflow.app${url.pathname}${url.search}`;
      
      return new Response(null, {
        status: 301,
        headers: {
          'Location': redirectUrl,
          'Cache-Control': 'public, max-age=3600' // 1時間キャッシュ
        }
      });
    }
    
    // その他のリクエストはそのまま通す（念のため）
    return new Response('Not Found', { status: 404 });
  }
};