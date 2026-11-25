// Fontes do Google servidas de uma cópia local, só para as capturas de revisão (o sandbox pode não alcançar o Google).
// Sem FONTES_DIR, nada muda: as fontes continuam barradas e o app usa as de reserva (Georgia/system-ui).
// Preparar a cópia: baixar o CSS de fonts.googleapis.com com user-agent de Chrome em <dir>/css.css e cada .woff2
// citado nele em <dir>/<caminho do gstatic com "/" trocada por "_">.
const fs = require('fs');
module.exports = async function fontes(p) {
  const D = process.env.FONTES_DIR; if (!D || !fs.existsSync(D + '/css.css')) return false;
  await p.route('https://fonts.googleapis.com/**', r => r.fulfill({ status: 200, contentType: 'text/css', headers: { 'access-control-allow-origin': '*' }, body: fs.readFileSync(D + '/css.css') }));
  await p.route('https://fonts.gstatic.com/**', r => { const f = D + '/' + new URL(r.request().url()).pathname.slice(1).replace(/\//g, '_');
    return fs.existsSync(f) ? r.fulfill({ status: 200, contentType: 'font/woff2', headers: { 'access-control-allow-origin': '*' }, body: fs.readFileSync(f) }) : r.abort(); });
  return true;
};
