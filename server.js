// 港上后端 + 合并订阅服务（零依赖，Node 内置 http）
// 域名一律取请求 Host 头，绝不硬编码；UUID/WS 路径取环境变量。
// 案件台账尚未接入：/api/verify 目前为平台验证桩，返回明确标注的演示结果；
// 台账（用户 Excel 导入）接入是服务器落定后的下一步，不在此处伪造数据。
const http = require('http');

const PORT = 3001;
const XRAY_UUID = process.env.XRAY_UUID || '';
const WS_PATH = process.env.XRAY_WS_PATH || '';
// Cloady 现役节点 v3（与 Cloady 端配置一致，Cloady 节点本身不动）
const CLOADY = {
  name: 'xray-usw1',
  server: 'xray-mf5hi8ry-ty.cloady.io',
  uuid: 'd7af0d0f-699c-4aec-9a58-5b48560e53ea',
  path: '/4e42599e040a',
};

function clashYaml(host) {
  return `port: 7890
socks-port: 7891
allow-lan: true
mode: rule
log-level: info
dns:
  enable: true
  ipv6: false
  listen: 0.0.0.0:1053
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  fake-ip-filter:
    - "*.lan"
    - "*.local"
    - "+.3gppnetwork.org"
  nameserver:
    - 8.8.8.8
    - 1.1.1.1
proxies:
  - name: ${CLOADY.name}
    type: vless
    server: ${CLOADY.server}
    port: 443
    uuid: ${CLOADY.uuid}
    alterId: 0
    cipher: auto
    udp: true
    tls: true
    servername: ${CLOADY.server}
    network: ws
    ws-opts:
      path: ${CLOADY.path}
      headers:
        Host: ${CLOADY.server}
  - name: xray-koyeb
    type: vless
    server: ${host}
    port: 443
    uuid: ${XRAY_UUID}
    alterId: 0
    cipher: auto
    udp: true
    tls: true
    servername: ${host}
    network: ws
    ws-opts:
      path: ${WS_PATH}
      headers:
        Host: ${host}
proxy-groups:
  - name: PROXY
    type: select
    proxies:
      - ${CLOADY.name}
      - xray-koyeb
      - DIRECT
rules:
  - DOMAIN-SUFFIX,3gppnetwork.org,DIRECT
  - MATCH,PROXY
`;
}

function subLinks(host) {
  const enc = encodeURIComponent;
  const c = `vless://${CLOADY.uuid}@${CLOADY.server}:443?encryption=none&security=tls&type=ws&host=${CLOADY.server}&path=${enc(CLOADY.path)}#${enc(CLOADY.name)}`;
  const k = `vless://${XRAY_UUID}@${host}:443?encryption=none&security=tls&type=ws&host=${host}&path=${enc(WS_PATH)}#${enc('xray-koyeb')}`;
  return c + '\n' + k + '\n';
}

const ADMIN_PAGE = `<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>港上管理后台</title></head>
<body style="font-family:sans-serif;max-width:640px;margin:40px auto;padding:0 16px">
<h1>港上管理后台（部署验证版）</h1>
<p>后端已跑通。案件台账尚未导入，核验接口当前返回演示结果。</p>
<h2>核验接口测试</h2>
<form id="f"><input name="phone" placeholder="手机号" style="padding:8px;width:200px">
<input name="code" placeholder="验证码" style="padding:8px;width:120px">
<button style="padding:8px 16px">核验</button></form>
<pre id="out"></pre>
<script>
document.getElementById('f').addEventListener('submit', async (e) => {
  e.preventDefault();
  const fd = new FormData(e.target);
  const r = await fetch('/api/verify', { method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone: fd.get('phone'), code: fd.get('code') }) });
  document.getElementById('out').textContent = JSON.stringify(await r.json(), null, 2);
});
</script>
<p><a href="/clash-meta.yaml">Clash Meta 订阅</a> · <a href="/sub">小火箭订阅</a> · <a href="/health">健康检查</a></p>
</body></html>`;

const server = http.createServer((req, res) => {
  const host = (req.headers.host || '').split(':')[0];
  const url = new URL(req.url, 'http://x');
  if (req.method === 'GET' && url.pathname === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true }));
    return;
  }
  if (req.method === 'GET' && url.pathname === '/clash-meta.yaml') {
    res.writeHead(200, { 'Content-Type': 'text/yaml; charset=utf-8' });
    res.end(clashYaml(host));
    return;
  }
  if (req.method === 'GET' && url.pathname === '/sub') {
    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end(subLinks(host));
    return;
  }
  if (req.method === 'POST' && url.pathname === '/api/verify') {
    let body = '';
    req.on('data', (c) => { body += c; });
    req.on('end', () => {
      let data = {};
      try { data = JSON.parse(body || '{}'); } catch (_) { /* ignore */ }
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        ok: true,
        demo: true,
        note: '演示结果：案件台账尚未导入，正式核验以导入的 Excel 台账为准',
        phone: data.phone || null,
        verified: false,
        reason: 'no-ledger-loaded',
      }));
    });
    return;
  }
  if (req.method === 'GET' && url.pathname === '/') {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(ADMIN_PAGE);
    return;
  }
  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('not found\n');
});

server.listen(PORT, '127.0.0.1', () => console.log('gangshang backend listening on 127.0.0.1:' + PORT));
