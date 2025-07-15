// WWW to non-WWW redirect worker
export default {
  async fetch(request) {
    const url = new URL(request.url);
    
    // www.jitsuflow.app を jitsuflow.app にリダイレクト
    if (url.hostname === 'www.jitsuflow.app') {
      url.hostname = 'jitsuflow.app';
      return Response.redirect(url.toString(), 301);
    }
    
    // その他のリクエストは通過
    return fetch(request);
  }
};