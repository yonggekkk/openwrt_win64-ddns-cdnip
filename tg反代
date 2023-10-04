const tg_host = "api.telegram.org";
addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request))
})
async function handleRequest(request) {
    var u = new URL(request.url);
    u.host = tg_host;
    var req = new Request(u, {
        method: request.method,
        headers: request.headers,
        body: request.body
    });
    const result = await fetch(req);
    return result;
}
