// Família Finance AI — frontend (v0.16) — Railway Function (Bun)
// Rotas: /  (SPA)  /manifest.json  /sw.js  /health

const SUPABASE_URL = "https://hrsinekxrfiphlhpoewp.supabase.co";
const ANON_KEY = "sb_publishable_MzeZ3Hg-lJRA6O_PZZiAIA_Y3dMoC4g";
const APP_VERSION = "0.19.0";

const MANIFEST = JSON.stringify({
  name: "Família Finance AI", short_name: "Finanças", start_url: "/", scope: "/",
  display: "standalone", background_color: "#F5F7F5", theme_color: "#0F6E6E", lang: "pt-BR",
  id: "/", description: "Finanças da família", orientation: "any",
  icons: [{ src: "/icon.png", sizes: "512x512", type: "image/png", purpose: "any" }, { src: "/icon.png", sizes: "512x512", type: "image/png", purpose: "maskable" }],
});

const ICON = Uint8Array.from(atob("iVBORw0KGgoAAAANSUhEUgAAAgAAAAIABAMAAAAGVsnJAAAAGFBMVEX////+///s9PQpfX0Qbm4Pbm4Obm4FZ2clk3L7AAALrElEQVR42u3dT28bxxkG8HfoICXrSty1FRioIwuS5fRQRmotFWgPguskPRs9FP0G/Xg+F7ErH1KgQBPrTy0DDRDJJlwkOcTc5RKBKaPN9CArpqSd4c5y3iFn5tEpEGAg+9P77vPsckmKP1HcPw0C"+"A".repeat(218)+"Cw+5NlNf/hOyEcvcxphY5IJJECyGKDHtJm8rKbRAkgi7WHGdGDdGF9P4kRoPhwe4eIiFbyrW6EAHJteyclIqKjnObS6ADkYHsnPYmAtPfdnd0kthjsd06PnzJxeH/d9N9f+qXnA3D5gXhbAdJvf/aqGdkEXO+OVKBs/nApshUYbLfPLMRRZOcA2TkbfHL+szwqgMEjOnvA4qv1mABkpyfP/ibPokqB4uu94blftb+XzWgmQC4ftS/8MqZzQH65e+Fw+9+txwNw6X6bYp4A2emWHK2M5yQ4eHI8vPBLIS4Pm3FMgOx0S//aeSwrcKEEnbC0RSQAF0tQrXOAvzdEit2upIhfFygtQTEBlJUgIiLRiASgtAQREeXtKADKSxAREa0lMQAM/qY6TBHFCqhKEBElUQCUlyAiouRqNwIAVQkiIpnmERQhdQkSjSUZ/gToSlD/RgTnAFUJIqL26n4EAMoSRKKI4ZUhTQlqL69FEIOaElQs7Ic/AboStLwVwWuD6hIkyHgAPATQlKCkMB4ADwGKXeUpUG7uh39DRFOCRI0B8A9AV4Ju7VH4ALoSdE+ED6ArQSu9JHwAXQm62qXgAeyWIA8B7JYg/wAslyD/ACyXIO8AbJcg7wBslyDvAGyXIN8ArJcg3wCslyDPAOyXIM8A7JcgvwAYSpBfAAwlyCsAjhLkFQBHCfIKgKME+QTAUoJ8AmApQR4B8JQgjwB4SpA/AEwlyB8AphLkDQBXCfIGgKsEeQPAVYJ8AWArQb4AsJUgTwD4SpAnAHwlyA8AxhLkBwBjCfICgLMEeQHAWYK8AOAsQT4AsJYgHwBYS5AHALwlyAMA3hI0+wDMJWj2AZhL0MwDcJegmQfgLkEzD8BdgmYdgL0EzToAewmacQD+EjTjAPwlaLYBHJSg2QZwUIJmGsBFCSJy9QEKbz762qgE3VCeAtvX9lK/ALKbCRHJHZNvQLh0v606BRZ/2SWvALKNL/KMRPLJy77BKfBT5QAs9BKvALKNB73nRNTIV+eEQQnKVAPwi65XAPLmgx1KiUge0mbVv53s/FOZgVe2uuQTwKC3k8qMiER6SH+s+CUY+hKU+PQ1O7JzlGY5EZHM0mefLc1SCXLyoaqDp/9+dfrfw/azhUqf/1/yidGnP821vEkeTYDs7Iz0mf78V+v57JQgFxMwODgePeLj7H8fHI8vQYt/VQ1AcuNVizyaANnZPbPMMvn8RT4Td4IcAQwenftss7zCEji5E+RmBeS1p8Nzw1xhCUo/MfpkAF6vDps+TUAxf+FvOX4J3NwJcgIgRckyj10CN3eC3ExA2TLL/pG2DjksQezngMHBsGyZ0yNdHXJYgrgnQHael3/8u24JXJYg7gkYPM3Lj1OXBC5LEPMEyEXVMuuSwGUJYgYoycDxS+C0BPGugHz9d1INs3oJnJYg5glQ/y3VS+C2BPECDLZ1/7+KJXBbglgBVBmorUOOSxDrOUCZgbo65LgEcU6AOgM1S+C6BHECaDJQvQQunglyBFB6HTg2CVyXIM4J6HTH3/k6vwTOSxDjSVBxHaivQ85LEN8EjMnA8iVwX4L4ANR9RrME7ksQG8D4DCxJgimUICKmF0eLG1W/Bkymnyc/JOO+O0xu7ic+TUCVDLywBNMoQWwrUCUDzy/BNEoQF4D+OlCRBNMoQUwAFTPw7BJMpQQxFaGx14FldWgqJYhnAipn4OgSZFMpQTwA468DS5ZgYyoliGUFtPdClUvwqqe6dkiLPx9zAtgvQuonHDVLsCunUYJYVsAoA+nHZ4emUoI4AAwz8Mc6NJUSxAFQ9Tqw4rcl85YgBgBNBtZ6wp23BDEAqDNQZDUELL47zA2A5jqwvZKZ/y2ZSxDDBCgbvWi8d7tvPADMJch+Dxhsq57yT8SW7PUzwwEotrg3wO4EqDNQ0Or+wUemS2Dz3WFOADQZWGwlc98bLgF7CbJ9LVDyXOjo4z2i99uvhcllAsszQZwToMnA4p4gSs2WgL8EWZ4AzXVgcv2aIKJ3//uT5wYDcPKPPJoATQae9Bnx8u5SOkMlyDKA+jowEW/OZiZL4KAE2QXQZ+Cb/6yeBC5KkF0AfQaeHlblJUgKJwNgD0BzHdhefXtNX3kJXJQgqwDjMpDMlkA4GgBrMTg+A0+PrFodclKCrE7A2Aw0WgI3JcjmBKifiUkb987e165Sh9yUIIsTUCkDqyeBoxJkEaBSBlZfAkclyN4KjLkOPP+7cUsgmot506sJqJqBFZfAVQmyNgGVM/D0p/Vi/R+JOgu5Hozmm4DKGVipDgmHA2BnAgwysEodclaCbE2ASQZWSAJ3JcjWBKifiRGvlS/uq5PAXQmyNAEVrwOrJoHDEmQJwDADxy2BwxJkZwWMM1C/BC5LkKUJMM5A7RK4LEF2ACrcCzVZAld3gqwB1MlATR0Sjgdg8nNArQxU1yGnJcjGBNTLQOUSuC1BNgBqZqBqCfifCbK8ArUzsHwJ0mLTaQZamIC6GTi6BOnbB6luLToegEkB6mfgyBKcCqTy5r0ukU8rID94JIeKu1q3qg2z6P1u+CxttVqtVnZlsZe6BniH715oxT9m+q+7tENERCvvbTkfgMkA5OKXFj78eP7JxyIjonThw/3ELwD1+wNNPvxYzO99Qg9pM3k5heOfCEAK5ac/G334sUge0wYdkpjC8U82Acr3RojGVaMPP07piFKayk9jqhk4QjCl458EYJLrwNn5aTh6PTBAgMmuAwMAmPA60HsA7XsjekkEEzDpdaDvADYz0EeAMDJwAoAwMrA+QCAZWB8gkAysDRBKBtafgEAysDZAKBlYFyCYDKwLEEwG1gQIJwNrAoSTgfUAAsrAmhMQTgbWAwgoA2sBhJSBtQBCysA6AEFlYB2AoDKQzJ8PkD99ONEzMf5PwPWQMrAGwGC7HVAGmgPITpcCykBzgGI3DykDzQFErx1SBhoDyPf7FFIGkvETIomqBtv9QvCZnYDGbhJUBhoD9DMZVAbWiMGwMtAcILAMtPbeYV8z0BRAvh9YBtr6RElvM9DSCvibgZYA/M1AUwAxCCwDzYtQYBlovgJJWBlo5RzgcwaaXw5fESG8HlgfYP5XeVAZWOOOUJKElIHGAOLg4h0xnzOwxknw/ElAFH4PgCnA3N08pAyscQ44WDr3fv8lERUAyZWz7/dfXkviApi/PfrJL6JY8PsUaA4gnox8V4hoL3t+CqxRhedu/bqfnB5/ser7AJjfERKHH2XPU8ooJVn8ZrHvO4D5Byi0Xvz+22+GaSsbvr5958tmfAD07n/uHLe+GV75+erdPd/PALVuioq5gz98kZL4+IedlGIEIDH3+GZK8rEI4Pjr3RYX6RERhXD4tV8XCOPg+b59Hg"+"A".repeat(246)+"VPn5PzzAQv6EsnASAAAAAElFTkSuQmCC"), c => c.charCodeAt(0));

const SW = `self.addEventListener('install',e=>self.skipWaiting());self.addEventListener('activate',e=>self.clients.claim());
self.addEventListener('fetch',e=>{const u=new URL(e.request.url);if(e.request.mode==='navigate'){e.respondWith(fetch(e.request).catch(()=>caches.match('app-shell')));}});
self.addEventListener('message',async e=>{if(e.data==='cache-shell'){const c=await caches.open('ffa-v1');const r=await fetch('./');c.put('app-shell',r);}});`;

const HTML = `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#0F6E6E">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<title>Família Finance AI</title>
<link rel="manifest" href="manifest.json"><link rel="icon" type="image/png" href="icon.png"><link rel="apple-touch-icon" href="icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
:root{--bg:#F5F7F5;--panel:#FFFFFF;--ink:#17241F;--ink2:#5B6B64;--line:#DCE3DF;--acc:#0F6E6E;--acc2:#E3F0EE;--pos:#237A48;--neg:#B5432D;--warn:#9A6B00;--tab:#FFFFFF;--wbg:#FFF4D6;--nbg:#FBE4DE;
 box-sizing:border-box;padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}
@media (prefers-color-scheme: dark){:root:not([data-theme=light]){--bg:#101715;--panel:#182220;--ink:#EEF3F0;--ink2:#9DB0A7;--line:#2A3733;--acc:#5FC2B8;--acc2:#1C3331;--pos:#6FCF8E;--neg:#F28B6F;--warn:#E3B94C;--tab:#131C19;--wbg:#3A2F14;--nbg:#3D211B;color-scheme:dark}}
:root[data-theme=dark]{--bg:#101715;--panel:#182220;--ink:#EEF3F0;--ink2:#9DB0A7;--line:#2A3733;--acc:#5FC2B8;--acc2:#1C3331;--pos:#6FCF8E;--neg:#F28B6F;--warn:#E3B94C;--tab:#131C19;--wbg:#3A2F14;--nbg:#3D211B;color-scheme:dark}
*{box-sizing:border-box}html,body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.45 "IBM Plex Sans",system-ui,sans-serif;font-feature-settings:"tnum"}
body{padding-bottom:calc(72px + env(safe-area-inset-bottom,0px))}
.wrap{max-width:720px;margin:0 auto;padding:16px}
h1{font-size:22px;font-weight:600;margin:4px 0 12px;letter-spacing:-.01em}h2{font-size:15px;font-weight:600;margin:20px 0 8px;color:var(--ink2)}
.num{font-variant-numeric:tabular-nums}.pos{color:var(--pos)}.neg{color:var(--neg)}.muted{color:var(--ink2)}.small{font-size:13px}
.panel{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:14px}
.row{display:flex;align-items:center;justify-content:space-between;gap:10px}
.kpis{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin:10px 0}.kpi{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:10px 12px}.kpi{min-width:0}.kpi .v{font-size:clamp(14px,4.2vw,19px);font-weight:600;white-space:nowrap}.kpi .l{font-size:12px;color:var(--ink2)}
.hero{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:14px}.hero .big{font-size:34px;font-weight:600;letter-spacing:-.02em;line-height:1.1}
svg.chart{width:100%;height:120px;display:block;margin-top:8px}
.list{display:flex;flex-direction:column;gap:1px;background:var(--line);border:1px solid var(--line);border-radius:12px;overflow:hidden}
.item{background:var(--panel);padding:11px 14px;display:flex;justify-content:space-between;gap:10px;align-items:center;cursor:pointer}.item:active{background:var(--acc2)}
.item .d{min-width:0}.item .t{font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.item .s{font-size:12.5px;color:var(--ink2);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.item .a{font-weight:600;white-space:nowrap}
.bar{height:6px;background:var(--acc2);border-radius:3px;overflow:hidden}.bar i{display:block;height:100%;background:var(--acc)}
button,select,input{font:inherit;color:inherit}button{background:var(--acc);color:#fff;border:0;border-radius:10px;padding:11px 16px;font-weight:600;cursor:pointer}button.ghost{background:transparent;color:var(--acc);border:1px solid var(--line)}button:disabled{opacity:.5}
input,select{width:100%;background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:10px 12px}input[type=checkbox]{width:auto;padding:0}
.filters{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin:8px 0 12px}.filters .full{grid-column:1/-1}
.tabs{position:fixed;left:0;right:0;bottom:0;background:var(--tab);border-top:1px solid var(--line);display:flex;padding-bottom:env(safe-area-inset-bottom,0px);z-index:5}
.tabs a{flex:1;min-width:0;text-align:center;padding:10px 1px 8px;color:var(--ink2);text-decoration:none;font-size:11px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-weight:500}.tabs a.on{color:var(--acc)}.tabs a span{display:block;font-size:20px;line-height:1.1}
.sheet{position:fixed;inset:0;background:rgba(0,0,0,.45);display:none;align-items:flex-end;z-index:10}.sheet.on{display:flex}.sheet .card{background:var(--panel);width:100%;max-width:720px;margin:0 auto;border-radius:16px 16px 0 0;padding:16px 16px calc(16px + env(safe-area-inset-bottom,0px));max-height:88vh;overflow:auto}
a{color:var(--acc)}.pill{white-space:nowrap;display:inline-block;padding:2px 8px;border-radius:999px;background:var(--acc2);color:var(--acc);font-size:12px;font-weight:500}.pill.warn{background:var(--wbg);color:var(--warn)}.pill.bad{background:var(--nbg);color:var(--neg)}
.toast{position:fixed;left:50%;transform:translateX(-50%);bottom:90px;background:var(--ink);color:var(--bg);padding:10px 16px;border-radius:10px;font-size:14px;display:none;z-index:20;align-items:center;gap:14px;max-width:calc(100% - 32px)}.toast button{background:none;border:0;color:var(--acc2);font:inherit;font-weight:700;padding:6px 4px;cursor:pointer;min-height:36px}body.loading::before{content:"";position:fixed;left:0;right:0;top:0;height:3px;z-index:30;background:linear-gradient(90deg,transparent,var(--acc),transparent);background-size:50% 100%;background-repeat:no-repeat;animation:ld 1s linear infinite}@keyframes ld{from{background-position:-50% 0}to{background-position:150% 0}}body.loading #app{opacity:.55;transition:opacity .2s .15s}.errbox{border-left:4px solid var(--neg)}.errbox .row{justify-content:flex-start;gap:10px;margin-top:10px;flex-wrap:wrap}.errbox button{white-space:nowrap}.toast{min-width:min(300px,calc(100% - 32px))}.toast span{flex:1}.failnote{border-left:4px solid var(--warn);margin-bottom:12px}.card{display:block;background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:11px 12px;color:inherit;text-decoration:none;text-align:left;font:inherit;cursor:pointer;min-width:0;width:100%}.card:hover{border-color:var(--acc)}.card:focus-visible{outline:2px solid var(--acc);outline-offset:2px}.card .k{font-size:12px;color:var(--ink2);font-weight:500}.card .v{font-size:clamp(15px,4.3vw,20px);font-weight:600;margin:2px 0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.card .s{font-size:12px;color:var(--ink2)}.card .go{float:right;color:var(--ink2)}.sobra .v{font-size:clamp(26px,8vw,34px);letter-spacing:-.02em}.sobra .s{font-size:13px}#lxtot .v{font-size:17px;white-space:nowrap}.cards2{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px;margin:8px 0 6px}.cards2 .card{min-height:104px}.cards2 .v{font-size:20px}.restam{color:var(--pos)}.passou{color:var(--neg)}.bopt{display:grid;gap:8px;margin-top:12px}.bopt button{width:100%}details.pat summary{cursor:pointer;list-style:none}details.pat summary::-webkit-details-marker{display:none}.dayh{display:flex;justify-content:space-between;font-size:13px;color:var(--ink2);padding:14px 4px 6px;font-weight:500}.dayh:first-child{padding-top:4px}.grp{margin:0 0 12px}.grp select{width:100%;margin:8px 0}.grp details{margin-top:8px}.grp summary{cursor:pointer;color:var(--acc);font-size:14px;padding:4px 0}.grp .list{margin-top:6px}.cards3{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px;margin:8px 0 10px}.need{background:var(--wbg);border:0;border-radius:12px;padding:4px 0;margin:10px 0}.need .h{font-size:12px;font-weight:600;color:var(--warn);padding:8px 14px 2px}.need a{display:flex;justify-content:space-between;gap:10px;padding:9px 14px;color:var(--ink);text-decoration:none;font-size:14px}.need a+a{border-top:1px solid color-mix(in srgb,var(--warn) 25%,transparent)}.need a span:last-child{color:var(--ink2)}.crumb{display:inline-block;font-size:14px;margin:0 0 2px;text-decoration:none}.hist{display:flex;gap:6px;align-items:flex-end;height:70px;margin-top:12px}.hist a{flex:1;height:100%;display:flex;flex-direction:column;justify-content:flex-end;align-items:center;gap:3px;text-decoration:none;color:var(--ink2);font-size:11px}.hist i{display:block;width:100%;background:var(--line);border-radius:3px;min-height:2px}.hist a.on i{background:var(--acc)}.hist a.on{color:var(--ink);font-weight:600}.foot{font-size:13px;color:var(--ink2);margin:18px 0 6px;line-height:1.6}
.login{max-width:380px;margin:12vh auto;display:flex;flex-direction:column;gap:10px}
.center{text-align:center;padding:30px 10px;color:var(--ink2)}
pre{white-space:pre-wrap;font:13px/1.5 ui-monospace,monospace;background:var(--acc2);padding:12px;border-radius:10px}
.alert{border-left:4px solid var(--warn)}.alert.alta{border-left-color:var(--neg)}.alert.baixa{border-left-color:var(--acc)}
.seg{display:flex;gap:6px;margin:8px 0}.seg a{flex:1;text-align:center;padding:7px;border:1px solid var(--line);border-radius:10px;text-decoration:none;color:var(--ink2);font-size:13px}.seg a.on{background:var(--acc2);color:var(--acc);border-color:var(--acc)}
label.chk{display:flex;gap:8px;align-items:center;font-size:14px}
@media (hover:hover){.item:hover{background:var(--acc2)}}
:focus-visible{outline:2px solid var(--acc);outline-offset:2px}.item:focus-visible{outline-offset:-2px}
.item{min-height:48px}a.small,.small a,a.crumb{display:inline-block;padding:9px 3px;margin:-9px -3px}.tabs a{min-height:48px}
.seg button{flex:1;background:transparent;color:var(--ink2);border:1px solid var(--line);border-radius:10px;padding:9px;font-weight:500;min-height:44px}.seg button.on{background:var(--acc2);color:var(--acc);border-color:var(--acc)}
.sr{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap}
@media (min-width:1000px){
 body{padding-bottom:0;padding-left:224px}
 .tabs{top:0;bottom:0;right:auto;width:224px;flex-direction:column;border-top:0;border-right:1px solid var(--line);padding:22px 12px;gap:2px}
 .tabs::before{content:"Família Finance";font-weight:600;font-size:16px;color:var(--ink);padding:0 12px 18px}
 .tabs a{flex:0 0 auto;display:flex;align-items:center;gap:12px;text-align:left;padding:10px 12px;border-radius:10px;font-size:14px;color:var(--ink)}
 .tabs a span{display:inline-block;width:22px;text-align:center;font-size:17px}
 .tabs a.on{background:var(--acc2);color:var(--acc)}.tabs a:hover{background:var(--acc2)}
 .wrap{max-width:1200px;padding:28px 36px 40px}
 .wrap>.row>select{width:auto;min-width:240px}
 h1{font-size:26px}.kpi .v{font-size:22px}.hero .big{font-size:40px}
 .secs{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:4px 28px;align-items:start}.sec{min-width:0;margin-bottom:6px}.sec>h2:first-child{margin-top:8px}.sec.full{grid-column:1/-1}
 .cards2{grid-template-columns:repeat(4,minmax(0,1fr))}
 .filters{grid-template-columns:1fr 1fr 2fr}.filters .full{grid-column:auto}
 .sheet{align-items:center}.sheet .card{max-width:560px;border-radius:16px;padding:22px}
 .toast{bottom:30px}
 .login{margin-top:18vh}
}
@media (prefers-reduced-motion: no-preference){.sheet .card{animation:up .18s ease-out}@keyframes up{from{transform:translateY(24px);opacity:.6}to{transform:none;opacity:1}}}
</style>
</head>
<body>
<div id="app"><div class="center">Carregando…</div></div>
<nav class="tabs" id="tabs" style="display:none">
 <a href="#inicio"><span>◔</span>Início</a><a href="#lancamentos"><span>≡</span>Lançamentos</a><a href="#cartao"><span>▭</span>Cartão</a><a href="#plano"><span>◎</span>Plano</a><a href="#revisao"><span>✎</span>Revisão<b id="pend"></b></a><a href="#operacao"><span>⚙</span>Mais</a>
</nav>
<div class="sheet" id="sheet" onclick="if(event.target===this)closeSheet()"><div class="card" id="sheetBody" role="dialog" aria-modal="true"></div></div>
<div class="toast" id="toast" role="status" aria-live="polite"></div>
<script type="module">
import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.49.1/+esm";
let RT=0;const FAILS={};
const tfetch=async(u,o)=>{const t=RT;const rest=String((u&&u.url)||u).indexOf('/rest/v1/')>=0;try{const r=await fetch(u,o);if(rest&&!r.ok)FAILS[t]=(FAILS[t]||0)+1;return r}catch(e){if(rest)FAILS[t]=(FAILS[t]||0)+1;throw e}};
const sb = createClient("${SUPABASE_URL}", "${ANON_KEY}",{global:{fetch:tfetch}});
const $ = (s)=>document.querySelector(s);
const brl = (v)=> (v==null?'—':Number(v).toLocaleString('pt-BR',{style:'currency',currency:'BRL'}));
const brl0 = (v)=> (v==null?'—':Math.round(Number(v)).toLocaleString('pt-BR',{style:'currency',currency:'BRL',maximumFractionDigits:0}));
const esc = (s)=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
let TT;const toast=(m,act,fn)=>{const t=$('#toast');t.innerHTML='';const s=document.createElement('span');s.textContent=m;t.appendChild(s);if(act){const b=document.createElement('button');b.type='button';b.textContent=act;b.onclick=()=>{t.style.display='none';fn()};t.appendChild(b)}t.style.display='flex';clearTimeout(TT);TT=setTimeout(()=>t.style.display='none',act?6000:2400)};
const ym=(d)=>d.toISOString().slice(0,7);
const mesAbv=(m)=>['jan','fev','mar','abr','mai','jun','jul','ago','set','out','nov','dez'][+m.slice(5,7)-1]+'/'+m.slice(2,4);
const mesNome=(m)=>{const [y,mo]=m.split('-');return new Date(Date.UTC(+y,+mo-1,1)).toLocaleDateString('pt-BR',{month:'long',year:'numeric',timeZone:'UTC'})};
const fmtD=(d)=>{const [y,m,dd]=d.split('-');return dd+'/'+m};
const TZ='America/Cuiaba';
const hojeCba=()=>new Intl.DateTimeFormat('en-CA',{timeZone:TZ,year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date());
const mesAtual=()=>hojeCba().slice(0,7);
let S={user:null,member:null,cats:[],accounts:[],month:mesAtual(),view:'inicio'};
let SHF=null;const sheetOn=()=>$('#sheet').classList.contains('on');
window.closeSheet=(silent)=>{if(!sheetOn())return;$('#sheet').classList.remove('on');if(silent!==true&&history.state&&history.state.sheet)history.back();if(SHF&&SHF.focus){try{SHF.focus({preventScroll:true})}catch(e){}}SHF=null};
function openSheet(html){$('#sheetBody').innerHTML=html;if(!sheetOn()){SHF=document.activeElement;$('#sheet').classList.add('on');history.pushState({sheet:1},'')}const f=$('#sheetBody').querySelector('input,select,textarea,button');if(f){try{f.focus({preventScroll:true})}catch(e){}}}
window.addEventListener('popstate',()=>{if(sheetOn()&&!(history.state&&history.state.sheet))closeSheet(true)});
document.addEventListener('keydown',(e)=>{if(e.key==='Escape'&&sheetOn())closeSheet()});

// ---------- autenticação ----------
async function boot(){
  if(location.hash.startsWith('#acesso=')){ await primeiroAcesso(); return; }
  const {data:{session}} = await sb.auth.getSession();
  S.user = session?.user ?? null;
  if(!S.user){ renderLogin(); return; }
  const {data:m} = await sb.from('household_members').select('*').eq('auth_user_id',S.user.id).maybeSingle();
  S.member=m;
  if(!m){ $('#app').innerHTML='<div class="wrap"><div class="panel">Seu login existe, mas ainda não está vinculado a um membro da família. Peça ao responsável para cadastrar o seu e-mail em Mais → Membros.</div><p><button class="ghost" id="out">Sair</button></p></div>'; $('#out').onclick=()=>sb.auth.signOut().then(()=>location.reload()); return; }
  const [{data:cats},{data:accs}] = await Promise.all([sb.from('categories').select('*').order('sort'), sb.from('accounts').select('id,name,subtype,number,balance,credit_limit,available_credit_limit')]);
  S.cats=cats||[]; S.accounts=accs||[];
  $('#tabs').style.display='flex';
  route();
  if('serviceWorker' in navigator){navigator.serviceWorker.register('sw.js').then(r=>r.active&&r.active.postMessage('cache-shell')).catch(()=>{});}
}
async function primeiroAcesso(){
  const q=new URLSearchParams(location.hash.slice(1));const th=q.get('acesso'),em=q.get('e')||'';
  $('#app').innerHTML='<div class="wrap"><div class="center">Validando o link…</div></div>';
  const {error}=await sb.auth.verifyOtp({token_hash:th,type:'recovery'});
  if(error){$('#app').innerHTML='<div class="wrap"><div class="panel">Este link de acesso expirou ou já foi usado. Peça um novo ao responsável (Mais → Membros).</div><p><a href="#" onclick="location.hash=\\'\\';location.reload()">Ir para o login</a></p></div>';return;}
  $('#app').innerHTML='<div class="wrap"><form class="login" id="pf"><h1>Bem-vinda(o)</h1><p class="muted small">Crie a sua senha para '+esc(em)+'. Mínimo de 8 caracteres.</p><input id="p1" type="password" autocomplete="new-password" placeholder="nova senha" required minlength="8"><input id="p2" type="password" autocomplete="new-password" placeholder="repita a senha" required minlength="8"><button>Salvar senha e entrar</button><p class="small muted" id="err"></p></form></div>';
  $('#pf').onsubmit=async(e)=>{e.preventDefault();if($('#p1').value!==$('#p2').value){$('#err').textContent='As senhas não conferem.';return;}const {error:ue}=await sb.auth.updateUser({password:$('#p1').value});if(ue){$('#err').textContent='Não foi possível salvar: '+ue.message;return;}history.replaceState(null,'',location.pathname);location.reload();};
}
function renderLogin(){
  $('#app').innerHTML='<div class="wrap"><form class="login" id="lf"><h1>Família Finance AI</h1><p class="muted small">Entre com o e-mail e a senha cadastrados.</p><input id="em" type="email" placeholder="e-mail" autocomplete="username" required><input id="pw" type="password" placeholder="senha" autocomplete="current-password" required><button>Entrar</button><p class="small muted" id="err"></p></form></div>';
  $('#lf').onsubmit=async(e)=>{e.preventDefault();const {error}=await sb.auth.signInWithPassword({email:$('#em').value.trim(),password:$('#pw').value});if(error){$('#err').textContent='Não foi possível entrar: '+error.message;return;}location.reload();};
}

// ---------- roteamento ----------
window.addEventListener('hashchange',()=>route('nav'));
const NAV=[],SNAP={};let LASTH=null;
function route(how){
  closeSheet(true);
  const h0=location.hash||'#inicio';let back=false,keep=null;
  if(how==='nav'){if(LASTH)SNAP[LASTH]={y:scrollY,html:$('#app').innerHTML};if(NAV.length>1&&NAV[NAV.length-2]===h0){NAV.pop();back=true}else{NAV.push(h0)}}
  else{keep=scrollY;if(!NAV.length)NAV.push(h0)}
  LASTH=h0;
  const h=h0.slice(1).split('?');S.view=h[0];
  document.querySelectorAll('.tabs a').forEach(a=>{const on=a.getAttribute('href')==='#'+(['simular','meta','fixas','orcamento'].includes(S.view)?'plano':S.view==='categoria'?'inicio':S.view);if(on)a.setAttribute('aria-current','page');else a.removeAttribute('aria-current')});document.querySelectorAll('.tabs a').forEach(a=>a.classList.toggle('on',a.getAttribute('href')==='#'+(['simular','meta','fixas','orcamento'].includes(S.view)?'plano':S.view==='categoria'?'inicio':S.view)));
  const q=new URLSearchParams(h[1]||'');
  const my=++RT;const snap=back?SNAP[h0]:null;
  if(snap){$('#app').innerHTML=snap.html;scrollTo(0,snap.y)}else if(how==='nav')scrollTo(0,0);
  document.body.classList.add('loading');
  const fn=({inicio:renderInicio,lancamentos:()=>renderLancamentos(q),cartao:()=>renderCartao(q),plano:renderPlano,simular:renderSimular,meta:renderMeta,fixas:renderFixas,revisao:renderRevisao,operacao:()=>renderOperacao(q),categoria:()=>renderCategoria(q),orcamento:()=>renderOrcamento(q)}[S.view]||renderInicio);
  let p;try{p=Promise.resolve(fn())}catch(e){p=Promise.reject(e)}
  p.then(()=>{if(my!==RT)return;if(FAILS[my])showFail();else{const y=snap?snap.y:keep;if(y!=null)scrollTo(0,y)}},(e)=>{if(my===RT)showFail(e)})
   .finally(()=>{if(my===RT)document.body.classList.remove('loading');delete FAILS[my]});
  refreshPending();
}
function showFail(e){const w=$('#app');window._failHtml=w.innerHTML;
  w.innerHTML='<div class="wrap"><div class="panel errbox"><b>Não consegui carregar esta tela.</b><p class="small muted">'+(e?esc(e.message||String(e)):'Parte dos dados não respondeu')+'. Para não mostrar números incompletos, a tela foi escondida.</p><div class="row"><button onclick="route()">Tentar de novo</button><button class="ghost" onclick="verMesmoAssim()">Ver o que carregou</button></div></div></div>'}
window.verMesmoAssim=()=>{$('#app').innerHTML='<div class="wrap"><div class="panel failnote small">Alguns dados não carregaram: os números abaixo podem estar incompletos. <a href="#" onclick="route();return false">Tentar de novo</a></div></div>'+(window._failHtml||'')};
window.route=route;
function replaceHash(h){const h0='#'+h;history.replaceState(history.state,'',h0);if(NAV.length)NAV[NAV.length-1]=h0;LASTH=h0}
async function refreshPending(){const {count}=await sb.from('transactions').select('id',{count:'exact',head:true}).eq('review_status','pending');$('#pend').textContent=count?' '+count:'';}
function monthPicker(fut){const opts=[];const c0=mesAtual(),cy=+c0.slice(0,4),cm=+c0.slice(5,7)-1;if(!fut&&S.month>c0)opts.push('<option value="'+S.month+'" selected>'+mesNome(S.month)+'</option>');for(let i=(fut?-12:0);i<14;i++){const m=ym(new Date(Date.UTC(cy,cm-i,1)));opts.push('<option value="'+m+'"'+(m===S.month?' selected':'')+'>'+mesNome(m)+'</option>')}return '<select id="mp" aria-label="Mês">'+opts.join('')+'</select>';}
function bindMonth(cb){$('#mp').onchange=(e)=>{S.month=e.target.value;cb();}}
const rerender=()=>{scrollTo(0,0);route()};

// ---------- Início ----------
async function renderInicio(){const _rt=RT;
  const m=S.month, prev=ym(new Date(Date.UTC(+m.slice(0,4),+m.slice(5,7)-2,1)));
  const [{data:sum},{data:cat},{data:daily},{data:dailyPrev},{data:sync},{data:alerts},{data:chk},{data:closing},{data:bud},{data:bills},{count:nSug}] = await Promise.all([
    sb.from('v_month_summary').select('*').in('month',[m+'-01',prev+'-01']),
    sb.from('v_category_month').select('*').eq('month',m+'-01').in('category_kind',['despesa','receita']),
    sb.from('v_daily_flow').select('*').gte('event_date',m+'-01').lt('event_date',nextMonth(m)+'-01'),
    sb.from('v_daily_flow').select('*').gte('event_date',prev+'-01').lt('event_date',m+'-01'),
    sb.from('v_sync_status').select('*'),
    sb.from('v_alerts').select('*'), sb.rpc('month_close_check',{p_month:m+'-01'}), sb.from('monthly_closings').select('*').eq('month',m+'-01').maybeSingle(),
    sb.from('v_budget_month').select('group_id,group_name,orcado,source').eq('month',m+'-01'),
    sb.from('v_card_bills').select('closing_date,due_date,total_lancamentos,status').eq('status','aberta').gt('total_lancamentos',0).order('closing_date').limit(1),
    sb.from('fixed_expenses').select('id',{count:'exact',head:true}).eq('source','sugerido').eq('is_active',true)]);
  const cur=(sum||[]).find(r=>r.month===m+'-01')||{}, pv=(sum||[]).find(r=>r.month===prev+'-01')||{};
  const groups={},recG={};(cat||[]).forEach(r=>{const bag=r.category_kind==='receita'?recG:groups;const g=bag[r.group_id]||(bag[r.group_id]={name:r.group_name,total:0,n:0,id:r.group_id});g.total+=Number(r.total);g.n+=Number(r.n)});
  (bud||[]).forEach(b=>{if(Number(b.orcado)>0&&!groups[b.group_id])groups[b.group_id]={name:b.group_name,total:0,n:0,id:b.group_id}});const BM={};(bud||[]).forEach(b=>{BM[b.group_id]=b});
  const cum=cumulative(daily||[],m), cumPrev=cumulative(dailyPrev||[],prev);
  const today=hojeCba();const isCur=m===mesAtual();
  const dayN=isCur?+today.slice(8,10):cum.length;
  const spentToDate=cum[Math.min(dayN,cum.length)-1]||0, prevSameDay=cumPrev[Math.min(dayN,cumPrev.length)-1]||0;
  const ritmoM=isCur?dayN/cum.length:1;
  const pctOf=(g)=>{const o=Number(BM[g.id]?.orcado||0);return o>0?Math.abs(g.total)/o:null};
  const gl=Object.values(groups).sort((a,b)=>{const pa=pctOf(a),pb=pctOf(b);if(pa==null&&pb==null)return a.total-b.total;if(pa==null)return 1;if(pb==null)return -1;return pb-pa});
  const st=(sync||[])[0];
  const res=Number(cur.resultado)||0, pres=Number(pv.resultado);
  const mesCurto=(x)=>mesNome(x).split(' ')[0];
  const recIds=Object.keys(recG);
  const bill=(bills||[])[0];const dias=bill?Math.round((Date.UTC(+bill.due_date.slice(0,4),+bill.due_date.slice(5,7)-1,+bill.due_date.slice(8,10))-Date.UTC(+today.slice(0,4),+today.slice(5,7)-1,+today.slice(8,10)))/86400000):null;
  const need=[];
  if(cur.pendentes)need.push(['#revisao',cur.pendentes+' lançamentos sem categoria',brl0(cur.valor_pendente)]);
  if(nSug)need.push(['#fixas',nSug+' contas fixas sugeridas para você confirmar','conferir']);
  if(isCur)(alerts||[]).filter(a=>a.kind!=='revisao_pendente').forEach(a=>need.push([alertLink(a),a.title,a.kind==='categoria_ritmo'?'ver':'abrir']));
  const NMAX=5;
  if(_rt!==RT)return;$('#app').innerHTML='<div class="wrap">'+
   '<div class="row"><h1>Início</h1>'+monthPicker()+'</div>'+
   '<a class="card sobra" href="#lancamentos?month='+m+'"><span class="go">›</span><div class="k">'+(res>=0?'Sobrou':'Faltou')+(isCur?' até hoje (dia '+dayN+')':' no mês')+'</div>'+
     '<div class="v num '+(res>=0?'pos':'neg')+'">'+brl0(Math.abs(res))+'</div>'+
     '<div class="s">Receitas '+brl0(cur.receitas)+' − despesas '+brl0(Math.abs(Number(cur.despesas)||0))+(isFinite(pres)&&pv.month?'. Em '+mesCurto(prev)+(pres>=0?' sobraram ':' faltaram ')+brl0(Math.abs(pres))+(isCur?' no mês todo':'')+'.':'.')+'</div></a>'+
   '<div class="cards3">'+
     '<button class="card" type="button" onclick="document.getElementById(&quot;cats&quot;).scrollIntoView({behavior:&quot;smooth&quot;})"><div class="k">Gastos'+(isCur?' até hoje':'')+'</div><div class="v num">'+brl0(-spentToDate)+'</div><div class="s">'+(prevSameDay?'vs '+brl0(-prevSameDay)+' '+delta(spentToDate,prevSameDay):'&nbsp;')+'</div></button>'+
     '<a class="card" href="#lancamentos?month='+m+(recIds.length===1?'&group='+recIds[0]:'')+'"><div class="k">Receitas</div><div class="v num pos">'+brl0(cur.receitas)+'</div><div class="s">'+(pv.month?mesCurto(prev)+': '+brl0(pv.receitas):'&nbsp;')+'</div></a>'+
     (bill?'<a class="card" href="#cartao"><div class="k">Fatura aberta</div><div class="v num">'+brl0(bill.total_lancamentos)+'</div><div class="s">'+(dias>0?'vence em '+dias+(dias===1?' dia':' dias'):dias===0?'vence hoje':'venceu '+fmtD(bill.due_date))+'</div></a>':'<a class="card" href="#cartao"><div class="k">Fatura aberta</div><div class="v num">—</div><div class="s">sem fatura aberta</div></a>')+
   '</div>'+
   (need.length?'<div class="need"><div class="h">Precisa de você · '+need.length+'</div>'+need.slice(0,NMAX).map(x=>'<a href="'+x[0]+'"><span>'+esc(x[1])+'</span><span>'+esc(x[2])+' ›</span></a>').join('')+(need.length>NMAX?'<a href="#inicio" onclick="return false"><span class="small muted">e mais '+(need.length-NMAX)+'</span><span></span></a>':'')+'</div>':'')+
   '<div class="hero"><div class="small muted">Ritmo de gastos'+(isCur?' · dia '+dayN+' de '+cum.length:'')+'</div><div class="small">Linha cheia: '+esc(mesCurto(m))+' · tracejada: '+esc(mesCurto(prev))+'</div>'+chart(cum,cumPrev,dayN)+'</div>'+
   '<h2 id="cats">Categorias · gasto × orçado</h2><div class="list">'+(gl.length?gl.map(g=>{const gasto=Math.abs(g.total),o=Number(BM[g.id]?.orcado||0),pr=BM[g.id]?.source==='proposta';const p=o>0?gasto/o:null;
     const cor=p==null?'var(--line)':p>1?'var(--neg)':p>ritmoM*1.1?'var(--warn)':'var(--acc)';
     return '<a class="item" href="#categoria?id='+encodeURIComponent(g.id)+'&month='+m+'" style="text-decoration:none;color:inherit"><div class="d" style="flex:1;min-width:0"><div class="row"><span class="t">'+esc(g.name)+(pr?' <span class="pill" style="font-size:11px">proposta</span>':'')+'</span><span class="num" style="font-weight:600">'+brl0(gasto)+'</span></div>'+
       '<div class="bar" style="position:relative;margin:6px 0 4px"><i style="width:'+(p==null?0:Math.min(100,Math.round(p*100)))+'%;background:'+cor+'"></i>'+(isCur&&o>0?'<b style="position:absolute;top:-2px;bottom:-2px;left:'+Math.round(ritmoM*100)+'%;width:2px;background:var(--ink2);opacity:.5"></b>':'')+'</div>'+
       '<div class="s">'+(p==null?'sem orçamento':(o-gasto>=0?'restam <b class="pos">'+brl0(o-gasto)+'</b>':'passou <b class="neg">'+brl0(gasto-o)+'</b>')+' de '+brl0(o)+' · '+Math.round(p*100)+'%')+'</div></div><span class="muted">›</span></a>'}).join(''):'<div class="item">Sem despesas no período.</div>')+'</div>'+
   '<p class="small muted">Mais estouradas primeiro. Verde: dentro do ritmo · amarelo: acima do ritmo · vermelho: passou do orçado'+(isCur?' · o traço marca onde o gasto deveria estar hoje':'')+'.</p>'+
   closeBlock(m,chk,closing)+
   '<p class="foot">'+S.accounts.filter(a=>a.subtype!=='CREDIT_CARD').map(a=>esc(a.subtype==='SAVINGS_ACCOUNT'?'Poupança':'Conta corrente')+' <b class="num">'+brl0(a.balance)+'</b>').join(' · ')+
     '<br>'+(st?('Banco atualizado em '+new Date(st.provider_updated_at).toLocaleString('pt-BR',{timeZone:TZ,day:'2-digit',month:'2-digit',hour:'2-digit',minute:'2-digit'})+(st.consent_warning?' · <span class="pill warn">consentimento vence em breve</span>':'')+(st.last_job_status==='FAILED'?' · <span class="pill bad">última sincronização falhou</span>':'')):'Sem conexão bancária registrada.')+'</p>'+
  '</div>';
  bindMonth(rerender);
  const cb=$('#closeBtn'); if(cb) cb.onclick=()=>doClose(m,cb.dataset.force==='1');
}
function alertLink(a){
  if(a.kind==='categoria_ritmo'){const nome=String(a.title||'').replace(/ acima do ritmo$/,'');const g=S.cats.find(c=>!c.parent_id&&c.name===nome);if(g)return '#categoria?id='+encodeURIComponent(g.id)+'&month='+mesAtual();}
  if(a.kind==='compra_grande'){const t=String(a.title||'');const i=t.indexOf(' em ');const mm=(a.ref_date?String(a.ref_date).slice(0,7):mesAtual());if(i>0)return '#lancamentos?month='+mm+'&search='+encodeURIComponent(t.slice(i+4).slice(0,40));}
  return {fatura_vencimento:'#cartao',fatura_acima_media:'#cartao',revisao_pendente:'#revisao',compra_grande:'#lancamentos?month='+mesAtual(),duplicidade:'#operacao?sec=dup',sincronizacao:'#operacao',consentimento:'#operacao',cartao_itau_teto:'#lancamentos?month='+mesAtual()}[a.kind]||'#inicio';
}
function alertRow(a){
  return '<a class="item alert '+esc(a.severity)+'" href="'+alertLink(a)+'" style="text-decoration:none;color:inherit"><div class="d"><div class="t">'+esc(a.title)+'</div><div class="s" style="white-space:normal">'+esc(a.detail)+'</div></div><span class="muted">›</span></a>'}
window.goBack=(fb)=>{if(NAV.length>1)history.back();else location.hash=fb;return false};
function voltar(rot,fallback){return '<a class="crumb" href="'+fallback+'" onclick="return goBack(&quot;'+fallback+'&quot;)">‹ '+esc(rot)+'</a>'}

// ---------- Detalhe de categoria (drill-down de Início) ----------
async function renderCategoria(q){const _rt=RT;
  const id=q.get('id')||'', m=q.get('month')||S.month, m0=addM(m,-6);
  const g=S.cats.find(c=>c.id===id)||{name:id};
  const [{data:hist},{data:bud},{data:tx}]=await Promise.all([
    sb.from('v_category_month').select('month,category_id,category_name,n,total').eq('group_id',id).gte('month',m0+'-01').lte('month',m+'-01'),
    sb.from('v_budget_month').select('orcado,source').eq('month',m+'-01').eq('group_id',id),
    sb.from('v_tx').select('id,event_date,amount,description,counterpart_name,category_id,category_name,installment_number,installment_total,card_last4,holder_name').eq('month',m+'-01').eq('group_id',id).order('amount').limit(2000)]);
  const byM={};(hist||[]).forEach(r=>{const k=String(r.month).slice(0,7);byM[k]=(byM[k]||0)+Math.abs(Number(r.total))});
  const meses=[];for(let k=-6;k<=0;k++)meses.push(addM(m,k));
  const gasto=byM[m]||0, o=Number((bud||[])[0]?.orcado||0);
  const isCur=m===mesAtual();const dim=new Date(Date.UTC(+m.slice(0,4),+m.slice(5,7),0)).getUTCDate();const ritmo=isCur?+hojeCba().slice(8,10)/dim:1;
  const p=o>0?gasto/o:null;const cor=p==null?'var(--line)':p>1?'var(--neg)':p>ritmo*1.1?'var(--warn)':'var(--acc)';
  const mx=Math.max(1,...meses.map(k=>byM[k]||0));
  const subs={};(hist||[]).filter(r=>String(r.month).slice(0,7)===m).forEach(r=>{const s=subs[r.category_id]||(subs[r.category_id]={id:r.category_id,nome:r.category_name,n:0,v:0});s.n+=Number(r.n);s.v+=Math.abs(Number(r.total))});
  const subL=Object.values(subs).sort((a,b)=>b.v-a.v);
  const rows=(tx||[]).filter(r=>Number(r.amount)<0);
  const parc=rows.filter(r=>Number(r.installment_total)>1), dia=rows.filter(r=>!(Number(r.installment_total)>1));
  const est={};dia.forEach(r=>{const nome=(r.counterpart_name||r.description||'').trim();const k=nome.toUpperCase();const e=est[k]||(est[k]={nome:nome,desc:r.description||nome,n:0,v:0});e.n++;e.v+=Math.abs(Number(r.amount))});
  const estL=Object.values(est).sort((a,b)=>b.v-a.v).slice(0,8);
  const base='#lancamentos?month='+m+'&group='+encodeURIComponent(id);
  if(_rt!==RT)return;$('#app').innerHTML='<div class="wrap">'+voltar('Início','#inicio')+
   '<div class="row"><h1>'+esc(g.name)+'</h1><span class="small muted">'+esc(mesNome(m))+'</span></div>'+
   '<div class="hero"><div class="small muted">Gasto em '+esc(mesNome(m).split(' ')[0])+'</div><div class="big num">'+brl(gasto)+'</div>'+
     '<div class="small">'+(p==null?'sem orçamento definido':(o-gasto>=0?'restam <b class="pos">'+brl0(o-gasto)+'</b>':'passou <b class="neg">'+brl0(gasto-o)+'</b>')+' de '+brl0(o)+' orçados · '+Math.round(p*100)+'%')+'</div>'+
     (p!=null?'<div class="bar" style="position:relative;margin-top:8px"><i style="width:'+Math.min(100,Math.round(p*100))+'%;background:'+cor+'"></i>'+(isCur?'<b style="position:absolute;top:-2px;bottom:-2px;left:'+Math.round(ritmo*100)+'%;width:2px;background:var(--ink2);opacity:.5"></b>':'')+'</div>':'')+
     '<div class="hist" aria-label="Gasto nos últimos 7 meses">'+meses.map(k=>'<a href="#categoria?id='+encodeURIComponent(id)+'&month='+k+'"'+(k===m?' class="on" aria-current="true"':'')+' title="'+esc(mesNome(k))+': '+brl0(byM[k]||0)+'"><i style="height:'+Math.round((byM[k]||0)/mx*100)+'%"></i>'+esc(mesNome(k).slice(0,3))+'</a>').join('')+'</div>'+
     '<div class="small muted" style="margin-top:4px">Toque num mês para ver o detalhe dele.</div></div>'+
   (subL.length>1?'<h2>Por subcategoria</h2><div class="list">'+subL.map(s=>'<a class="item" href="#lancamentos?month='+m+'&cat='+encodeURIComponent(s.id)+'" style="text-decoration:none;color:inherit"><div class="d"><div class="t">'+esc(s.nome)+'</div><div class="s">'+s.n+' lançamentos</div></div><div class="a num">'+brl0(s.v)+' ›</div></a>').join('')+'</div>':'')+
   (estL.length?'<h2>Onde mais gastou</h2><div class="list">'+estL.map(e=>'<a class="item" href="'+base+'&search='+encodeURIComponent(e.desc.slice(0,40))+'" style="text-decoration:none;color:inherit"><div class="d" style="min-width:0"><div class="t">'+esc(e.nome)+'</div><div class="s">'+e.n+(e.n===1?' lançamento':' lançamentos')+'</div></div><div class="a num">'+brl0(e.v)+' ›</div></a>').join('')+'</div>':'')+
   (parc.length?'<h2>Parcelas que caem neste mês</h2><div class="list">'+parc.map(r=>'<div class="item"><div class="d" style="min-width:0"><div class="t">'+esc(r.counterpart_name||r.description)+'</div><div class="s">parcela '+r.installment_number+'/'+r.installment_total+(r.card_last4?' · '+esc(r.holder_name||'cartão')+' '+esc(r.card_last4):'')+'</div></div><div class="a num">'+brl(Math.abs(Number(r.amount)))+'</div></div>').join('')+'</div><p class="small muted">Total em parcelas: '+brl0(parc.reduce((s,r)=>s+Math.abs(Number(r.amount)),0))+'. Elas entram pelo valor real no mês em que caem.</p>':'')+
   '<p style="margin-top:16px"><a class="card" href="'+base+'" style="text-align:center">Ver todos os '+rows.length+' lançamentos de '+esc(g.name)+' ›</a></p>'+
  '</div>';
}

function closeBlock(m,c,cl){if(!c)return'';
  if(cl&&cl.status==='fechado')return '<h2>Fechamento do mês</h2><div class="panel row"><span>Mês fechado em '+new Date(cl.closed_at).toLocaleDateString('pt-BR')+(cl.checklist&&!cl.checklist.pronto?' (com ressalva)':'')+'</span><span class="pill">fechado</span></div>';
  if(!c.mes_encerrado)return '';
  const f=c.fatura||{};const items=[
   [c.pendentes_categoria==0, c.pendentes_categoria==0?'Todos os lançamentos classificados':c.pendentes_categoria+' lançamentos sem categoria ('+brl0(c.valor_pendente)+')'],
   [c.duplicidades_abertas==0, c.duplicidades_abertas==0?'Sem duplicidades em aberto':c.duplicidades_abertas+' duplicidades a confirmar'],
   [f.status==='paga', f.fechamento?('Fatura '+fmtD(f.fechamento)+': '+brl0(f.lancamentos)+(f.pago?' · paga '+brl0(f.pago):' · ainda não paga')+(f.pdf?' · PDF '+brl0(f.pdf):'')):'Sem fatura neste mês'],
   [true,'Fechamento da fatura: '+({pdf:'confirmado pelo PDF',pluggy_parcelas:'identificado pelas parcelas',estimado:'estimado'}[f.fonte_fechamento]||'—')]];
  const owner=['owner','admin'].includes(S.member?.role);
  return '<h2>Fechamento do mês</h2><div class="panel">'+items.map(i=>'<div class="small" style="margin:3px 0">'+(i[0]?'<span class="pos">✓</span> ':'<span class="neg">•</span> ')+esc(i[1])+'</div>').join('')+
   (owner?'<p style="margin:10px 0 0"><button id="closeBtn" data-force="'+(c.pronto?'0':'1')+'"'+(c.pronto?'':' class="ghost"')+'>'+(c.pronto?'Fechar o mês':'Fechar com ressalva')+'</button></p>':'')+'</div>'}
function doClose(m,force){openSheet('<b>Fechar '+esc(mesNome(m))+'?</b><p class="small muted">O mês fica registrado como fechado, com um retrato dos números de hoje. Para mudar depois, é preciso reabrir o mês informando o motivo.</p>'+
   (force?'<label class="small" for="cnotes">Ressalva (o que ficou pendente) — obrigatória</label><textarea id="cnotes" style="width:100%;height:80px"></textarea>':'')+
   '<div class="row" style="margin-top:12px"><button class="ghost" onclick="closeSheet()">Cancelar</button><button onclick="confirmClose(\\''+m+'\\','+(force?1:0)+')">'+(force?'Fechar com ressalva':'Fechar o mês')+'</button></div>')}
window.confirmClose=async(m,force)=>{const notes=force?($('#cnotes').value||'').trim():null;if(force&&!notes){toast('Escreva a ressalva antes de fechar');return;}
  const {error}=await sb.rpc('close_month',{p_month:m+'-01',p_notes:notes,p_force:!!force});if(error){toast('Não fechou: '+error.message);return;}closeSheet();toast('Mês fechado');route();}
function nextMonth(m){return ym(new Date(Date.UTC(+m.slice(0,4),+m.slice(5,7),1)))}
function cumulative(rows,m){const days=new Date(Date.UTC(+m.slice(0,4),+m.slice(5,7),0)).getUTCDate();const by={};rows.forEach(r=>{by[r.event_date]=(by[r.event_date]||0)+Number(r.saidas||0)});const out=[];let acc=0;for(let d=1;d<=days;d++){acc+=by[m+'-'+String(d).padStart(2,'0')]||0;out.push(acc)}return out}
function delta(a,b){if(!b)return'';const p=Math.round((Math.abs(a)/Math.abs(b)-1)*100);return'<span class="'+(p>0?'neg':'pos')+'">('+(p>0?'+':'')+p+'%)</span>'}
function chart(cur,prev,dayN){const W=600,H=120,P=6;const max=Math.max(Math.abs(Math.min(...cur,0)),Math.abs(Math.min(...prev,0)),1);const n=Math.max(cur.length,prev.length);const x=i=>P+(W-2*P)*i/(n-1), y=v=>H-P-(H-2*P)*Math.abs(v)/max;
  const path=(arr,upto)=>arr.slice(0,upto).map((v,i)=>(i?'L':'M')+x(i).toFixed(1)+' '+y(v).toFixed(1)).join(' ');
  return '<svg class="chart" viewBox="0 0 '+W+' '+H+'" preserveAspectRatio="none" aria-label="Gasto acumulado por dia, mês atual e anterior"><path d="'+path(prev,prev.length)+'" fill="none" stroke="var(--line)" stroke-width="3" stroke-dasharray="4 4"/><path d="'+path(cur,dayN)+'" fill="none" stroke="var(--acc)" stroke-width="3" stroke-linejoin="round"/></svg>';}

// ---------- Lançamentos ----------
const PAGE=100;
function lxQuery(f,month,cols,opt){let sel=sb.from('v_tx').select(cols,opt).order('event_date',{ascending:false}).order('id',{ascending:false});
  sel=f.bill?sel.eq('bill_closing_date',f.bill):f.all?sel.gte('month',addM(mesAtual(),-6)+'-01'):sel.eq('month',month+'-01');
  if(f.holder)sel=sel.eq('holder_name',f.holder);if(f.group)sel=sel.eq('group_id',f.group);if(f.cat)sel=sel.eq('category_id',f.cat);if(f.account)sel=sel.eq('account_id',f.account);
  if(f.search){const t=f.search.replace(/[,()%*:"\\\\]/g,' ').replace(/\\s+/g,' ').trim();if(t)sel=sel.or('description.ilike.*'+t+'*,counterpart_name.ilike.*'+t+'*')}
  if(f.pending)sel=sel.eq('review_status','pending');return sel}
async function lxTotals(f,month){const t={ent:0,sai:0,n:0};for(let from=0;from<20000;from+=1000){const {data,error}=await lxQuery(f,month,'amount').range(from,from+999);if(error)throw error;(data||[]).forEach(r=>{const v=Number(r.amount);if(v>0)t.ent+=v;else t.sai+=v;t.n++});if(!data||data.length<1000)break}return t}
async function lxFetch(L,n){const [pg,tt]=await Promise.all([lxQuery(L.f,L.month,'*',{count:'exact'}).range(0,n-1),lxTotals(L.f,L.month)]);if(pg.error)throw pg.error;const rows=pg.data||[];return {rows,total:pg.count==null?rows.length:pg.count,tt}}
const diaNome=(d)=>{const h=hojeCba();if(d===h)return 'Hoje · '+fmtD(d);const y=new Date(Date.UTC(+h.slice(0,4),+h.slice(5,7)-1,+h.slice(8,10)-1)).toISOString().slice(0,10);if(d===y)return 'Ontem · '+fmtD(d);const w=new Date(d+'T12:00:00Z').toLocaleDateString('pt-BR',{weekday:'short',timeZone:'UTC'}).replace('.','');return w.charAt(0).toUpperCase()+w.slice(1)+' · '+fmtD(d)+(d.slice(0,4)!==h.slice(0,4)?'/'+d.slice(0,4):'')};
function lxTot(){const t=(window._lx||{}).tt||{ent:0,sai:0,n:0},liq=t.ent+t.sai;
  return '<div class="cards3"><div class="card"><div class="k">Entradas</div><div class="v num pos">'+brl0(t.ent)+'</div></div><div class="card"><div class="k">Saídas</div><div class="v num">'+brl0(-t.sai)+'</div></div><div class="card"><div class="k">Líquido</div><div class="v num '+(liq<0?'neg':'pos')+'">'+brl0(liq)+'</div></div></div>'+
   '<p class="small muted">'+t.n+(t.n===1?' lançamento':' lançamentos')+' com estes filtros (transferências entre contas próprias entram nos dois lados).</p>'}
function lxList(){const R=window._rows||[],L=window._lx||{};if(!R.length)return '<div class="list"><div class="item">Nada encontrado com esses filtros.</div></div>';
  const days=[];let cur=null;R.forEach(r=>{if(!cur||cur.d!==r.event_date){cur={d:r.event_date,rows:[],s:0};days.push(cur)}cur.rows.push(r);cur.s+=Number(r.amount)});
  const rest=Math.max(0,(L.total||0)-R.length);
  return days.map(g=>'<div class="dayh"><span>'+diaNome(g.d)+'</span><span class="num">'+brl(g.s)+'</span></div><div class="list">'+g.rows.map(txRow).join('')+'</div>').join('')+
   (rest?'<p style="text-align:center;margin:14px 0"><button class="ghost" id="lxmore" onclick="lxMore()">Carregar mais '+Math.min(PAGE,rest)+' · faltam '+rest+'</button></p>':'<p class="small muted" style="text-align:center;margin:14px 0">Fim da lista · '+R.length+(R.length===1?' lançamento':' lançamentos')+'</p>')}
function lxPaint(){if(!$('#lxlist'))return;$('#lxtot').innerHTML=lxTot();$('#lxlist').innerHTML=lxList()}
window.lxMore=async()=>{const L=window._lx;if(!L||L.busy)return;L.busy=1;const b=$('#lxmore');if(b){b.disabled=true;b.textContent='Carregando…'}
  const n0=window._rows.length;const {data,error,count}=await lxQuery(L.f,L.month,'*',{count:'exact'}).range(n0,n0+PAGE-1);L.busy=0;if(window._lx!==L)return;
  if(error){toast('Não carregou: '+error.message);if(b){b.disabled=false;b.textContent='Tentar de novo'}return}
  window._rows=window._rows.concat(data||[]);if(count!=null)L.total=count;L.n=window._rows.length;lxPaint()};
async function lxSearch(){const L=window._lx,i=$('#fs');if(!L||!i)return;const v=i.value.trim();if(v===L.f.search)return;
  const p=new URLSearchParams((location.hash.split('?')[1])||'');if(v)p.set('search',v);else p.delete('search');replaceHash('lancamentos?'+p);
  L.f.search=v;L.key=JSON.stringify([L.f,L.month]);const seq=L.seq=(L.seq||0)+1;document.body.classList.add('loading');
  let r;try{r=await lxFetch(L,PAGE)}catch(e){if(seq===L.seq){document.body.classList.remove('loading');toast('Busca falhou: '+(e.message||e))}return}
  if(seq!==L.seq||window._lx!==L)return;document.body.classList.remove('loading');window._rows=r.rows;L.total=r.total;L.tt=r.tt;L.n=r.rows.length;lxPaint()}
async function renderLancamentos(q){const _rt=RT;
  const month=q.get('month')||S.month; S.month=month;
  const f={all:q.get('all')==='1',bill:q.get('bill')||'',holder:q.get('holder')||'',group:q.get('group')||'',cat:q.get('cat')||'',account:q.get('account')||'',search:q.get('search')||'',pending:q.get('pending')==='1'};
  const L={f,month,key:JSON.stringify([f,month])};const old=window._lx;
  const n=old&&old.key===L.key?Math.min(1000,Math.max(PAGE,old.n||0)):PAGE;
  const r=await lxFetch(L,n);
  const groups=S.cats.filter(c=>!c.parent_id);
  if(_rt!==RT)return;
  window._rows=r.rows;L.total=r.total;L.tt=r.tt;L.n=r.rows.length;window._lx=L;
  $('#app').innerHTML='<div class="wrap"><div class="row"><h1>Lançamentos</h1>'+monthPicker()+'</div>'+
   '<div class="filters"><select id="fg"><option value="">Todas as categorias</option>'+groups.map(g=>'<option value="'+g.id+'"'+(g.id===f.group?' selected':'')+'>'+esc(g.name)+'</option>').join('')+'</select>'+
   '<select id="fa"><option value="">Todas as contas</option>'+S.accounts.map(a=>'<option value="'+a.id+'"'+(a.id===f.account?' selected':'')+'>'+esc(a.subtype==='CREDIT_CARD'?'Cartão '+a.number:a.subtype==='SAVINGS_ACCOUNT'?'Poupança':'Conta corrente')+'</option>').join('')+'</select>'+
   '<input class="full" id="fs" type="search" aria-label="Buscar lançamentos" autocomplete="off" placeholder="buscar por descrição ou estabelecimento" value="'+esc(f.search)+'"></div>'+
   (f.all?'<p><span class="pill">Últimos 6 meses</span> <a class="small" href="#lancamentos">limpar</a></p>':'')+(f.bill?'<p><span class="pill">Fatura com fechamento em '+fmtD(f.bill)+'/'+f.bill.slice(0,4)+(f.holder?' · '+esc(f.holder):'')+'</span> <a class="small" href="#lancamentos">limpar</a></p>':'')+
   (f.cat?'<p><span class="pill">'+esc((S.cats.find(c=>c.id===f.cat)||{}).name||f.cat)+'</span> <a class="small" href="#lancamentos?month='+month+'">limpar</a></p>':'')+(f.pending?'<p><span class="pill warn">Só pendentes</span> <a class="small" href="#lancamentos?month='+month+'">limpar</a></p>':'')+
   '<div id="lxtot">'+lxTot()+'</div><div id="lxlist">'+lxList()+'</div></div>';
  const go=()=>{const p=new URLSearchParams({month:S.month});if($('#fg').value)p.set('group',$('#fg').value);if($('#fa').value)p.set('account',$('#fa').value);if($('#fs').value.trim())p.set('search',$('#fs').value.trim());location.hash='lancamentos?'+p};
  bindMonth(go);$('#fg').onchange=go;$('#fa').onchange=go;
  $('#fs').oninput=()=>{clearTimeout(window._lxT);window._lxT=setTimeout(lxSearch,350)};
  $('#fs').onkeydown=(e)=>{if(e.key==='Enter'){clearTimeout(window._lxT);lxSearch();e.target.blur()}};
}
function txRow(r){return '<div class="item" onclick="openTx(\\''+r.id+'\\')"><div class="d"><div class="t">'+esc(r.counterpart_name||r.description)+'</div><div class="s">'+fmtD(r.event_date)+' · '+esc(r.category_name||'sem categoria')+(r.card_last4?' · '+esc(r.holder_name||'cartão')+' '+esc(r.card_last4):'')+(r.review_status==='pending'?' · <span class="pill warn">revisar</span>':'')+'</div></div><div class="a num '+(Number(r.amount)<0?'':'pos')+'">'+brl(r.amount)+'</div></div>'}
window.openTx=(id)=>{const r=(window._rows||[]).find(x=>x.id===id);if(!r)return;
  const opts=S.cats.map(c=>'<option value="'+c.id+'"'+(c.id===r.category_id?' selected':'')+'>'+(c.parent_id?'  ↳ ':'')+esc(c.name)+'</option>').join('');
  openSheet('<div class="row"><b>'+esc(r.description)+'</b><span class="num '+(Number(r.amount)<0?'neg':'pos')+'" style="font-weight:600">'+brl(r.amount)+'</span></div>'+
   '<p class="small muted">'+fmtD(r.event_date)+'/'+r.event_date.slice(0,4)+' · '+esc(r.account_name)+(r.counterpart_name?' · '+esc(r.counterpart_name):'')+(r.installment_total?' · parcela '+r.installment_number+'/'+r.installment_total:'')+'</p>'+
   '<p class="small">Origem: '+esc(r.source==='pluggy'?'Open Finance (Santander via Pluggy)':r.source)+' · Classificação: '+esc(srcLabel(r.category_source))+(r.category_confidence?' · confiança '+Math.round(r.category_confidence*100)+'%':'')+'</p>'+
   '<select id="cx">'+opts+'</select><label class="chk" style="margin:10px 0"><input type="checkbox" id="rule"> Aplicar a lançamentos iguais no futuro (cria regra)</label>'+
   '<div class="row"><button class="ghost" onclick="closeSheet()">Cancelar</button><button onclick="saveTx(\\''+r.id+'\\')">Salvar categoria</button></div>');
}
function srcLabel(s){return {ajuste_usuario:'ajuste manual',pessoa:'pessoa conhecida',regra_sistema:'regra do sistema',regra_estabelecimento:'estabelecimento',padrao_operacao:'tipo de operação',mcc:'ramo do estabelecimento (sugestão)',pendente:'pendente'}[s]||s||'—'}
window.saveTx=async(id)=>{const cat=$('#cx').value,rule=$('#rule').checked;const prev=((window._rows||[]).find(x=>x.id===id)||{}).category_id;
  const {error}=await sb.rpc('set_transaction_category',{p_tx:id,p_category:cat,p_create_rule:rule});if(error){toast('Não salvou: '+error.message);return;}closeSheet();
  if(prev&&prev!==cat&&!rule)toast('Categoria salva','Desfazer',async()=>{const r=await sb.rpc('set_transaction_category',{p_tx:id,p_category:prev,p_create_rule:false});toast(r.error?'Não desfez: '+r.error.message:'Categoria anterior restaurada');route()});
  else toast(rule?'Categoria salva e regra criada':'Categoria salva');route();}

// ---------- Cartão ----------
async function renderCartao(q){const _rt=RT;
  const card=S.accounts.find(a=>a.subtype==='CREDIT_CARD');
  const [{data:bills},{data:hold}]=await Promise.all([sb.from('v_card_bills').select('*').order('closing_date',{ascending:false}).limit(14),
    sb.from('v_tx').select('bill_closing_date,holder_name,amount').eq('account_subtype','CREDIT_CARD').gte('bill_closing_date',new Date(Date.now()-75*864e5).toISOString().slice(0,10))]);
  const B=bills||[];const cur=B.filter(b=>b.status!=='paga').sort((a,b)=>a.closing_date<b.closing_date?-1:1);
  const byH={};(hold||[]).forEach(r=>{const k=r.bill_closing_date+'|'+(r.holder_name||'?');byH[k]=(byH[k]||0)-Number(r.amount)});
  const holders=(c)=>['Hugo','Juliana'].map(h=>byH[c+'|'+h]?'<a class="pill" style="text-decoration:none;margin-right:4px" href="#lancamentos?bill='+c+'&holder='+h+'">'+h+' '+brl0(byH[c+'|'+h])+'</a>':'').join('');
  const st={aberta:'<span class="pill">aberta</span>',fechada:'<span class="pill warn">fechada · a pagar</span>',paga:'<span class="pill">paga</span>'};
  const src={pdf:'fechamento confirmado pelo PDF',pluggy_parcelas:'fechamento identificado pelas parcelas',estimado:'fechamento estimado'};
  const big=(b)=>'<div class="hero" style="margin-bottom:10px"><div class="row"><div class="small muted">Fatura · fecha '+fmtD(b.closing_date)+' · vence '+fmtD(b.due_date)+'</div>'+st[b.status]+'</div><div class="big num">'+brl(b.total_lancamentos)+'</div><div class="small muted">'+b.n_lancamentos+' lançamentos · '+src[b.source]+'</div><div style="margin-top:8px">'+holders(b.closing_date)+'</div><p style="margin:10px 0 0"><a href="#lancamentos?bill='+b.closing_date+'">Ver lançamentos ›</a></p></div>';
  if(_rt!==RT)return;$('#app').innerHTML='<div class="wrap"><h1>Cartão</h1>'+
   (card?'<p class="small muted">'+esc(card.name)+' final '+esc(card.number)+' · limite '+brl0(card.credit_limit)+' · disponível '+brl0(card.available_credit_limit)+'</p>':'')+
   cur.map(big).join('')+
   '<h2>Faturas anteriores</h2><div class="list">'+B.filter(b=>b.status==='paga').map(b=>{const ref=b.pdf_total??b.paid_amount;const d=ref!=null?Number(b.total_lancamentos)-Number(ref):null;
     return '<a class="item" style="text-decoration:none;color:inherit" href="#lancamentos?bill='+b.closing_date+'"><div class="d"><div class="t">'+mesNome(b.competence_month.slice(0,7))+'</div><div class="s">fechou '+fmtD(b.closing_date)+' · pago '+brl0(b.paid_amount)+(d!=null&&Math.abs(d)>=1?' · diferença '+brl0(d):'')+'</div></div><div class="a num">'+brl0(ref??b.total_lancamentos)+'</div></a>'}).join('')+'</div>'+
   '<p class="small muted">A Pluggy não envia as faturas do Santander. O total por fatura é calculado pelos lançamentos e pode diferir do valor pago em até ~1% (compras próximas ao fechamento). O valor oficial é o débito na conta corrente.</p></div>';
}

// ---------- Plano: painel de 4 cards (Orçamento, Meta de sobra, Contas fixas, Simular) + Reservas + Patrimônio ----------
async function orcDados(m){
  const [bud,mc,fut]=await Promise.all([sb.from('v_budget_month').select('*').eq('month',m+'-01'),sb.from('v_month_commitments').select('*').eq('month',m+'-01'),sb.from('v_card_future_installments').select('competence_month,valor')]);
  for(const r of [bud,mc,fut])if(r.error)throw r.error;
  const MC={};(mc.data||[]).forEach(r=>{MC[r.group_id]={p:Number(r.parcelas_cartao),n:Number(r.n_parcelas),c:Number(r.compromissos_pendentes),nomes:r.nomes||''}});
  const futuro=m>mesAtual();const totP=(mc.data||[]).reduce((s,r)=>s+Number(r.parcelas_cartao),0),totC=(mc.data||[]).reduce((s,r)=>s+Number(r.compromissos_pendentes),0);
  const B=(bud.data||[]).filter(b=>Number(b.orcado)>0||Number(b.gasto)>0||MC[b.group_id]).sort((a,b)=>b.orcado-a.orcado);
  const tO=B.reduce((s,b)=>s+Number(b.orcado),0),tG=B.reduce((s,b)=>s+Number(b.gasto),0);
  const isCur=m===mesAtual();const day=+hojeCba().slice(8,10);const dim=new Date(Date.UTC(+m.slice(0,4),+m.slice(5,7),0)).getUTCDate();const ritmo=isCur?day/dim:1;
  const livre=tO-tG-totC-(futuro?totP:0);
  return {B,MC,futuro,totP,totC,tO,tG,isCur,ritmo,livre,fut:fut.data||[]}}
const restaTxt=(v)=>v>=0?'<span class="restam">restam '+brl0(v)+'</span>':'<span class="passou">passou '+brl0(-v)+'</span>';
async function renderPlano(){const _rt=RT;
  const m=S.month;
  const [O,r2]=await Promise.all([orcDados(m),Promise.all([sb.from('v_net_worth').select('*').maybeSingle(),sb.from('v_goals').select('*').order('created_at'),sb.from('v_investments_latest').select('*').gt('balance',0),
    sb.from('plan_settings').select('*').eq('key','sobra_meta').maybeSingle(),sb.from('v_sim_base').select('receita_mensal').maybeSingle(),sb.from('v_fixed_expenses').select('valor_atual,pago_mes,is_active,end_month,source'),sb.from('sim_scenarios').select('id',{count:'exact',head:true})])]);
  for(const r of r2)if(r.error)throw r.error;
  const [{data:nw},{data:goals},{data:inv},{data:ps},{data:sb0},{data:fe},{count:nSim}]=r2;
  const n=nw||{};window._goals=goals||[];const hoje=mesAtual();
  const fa=(fe||[]).filter(f=>f.is_active&&(!f.end_month||f.end_month.slice(0,7)>=hoje));const fT=fa.reduce((s,f)=>s+Number(f.valor_atual||0),0),fP=fa.reduce((s,f)=>s+Math.min(Number(f.pago_mes||0),Number(f.valor_atual||0)),0),fSug=fa.filter(f=>f.source==='sugerido').length;
  const sobraOrc=(sb0?.receita_mensal||0)-O.tO;
  if(_rt!==RT)return;$('#app').innerHTML='<div class="wrap"><div class="row"><h1>Plano</h1>'+monthPicker(true)+'</div>'+
   '<div class="cards2">'+
    '<a class="card" href="#orcamento?month='+m+'"><div class="k">Orçamento de '+esc(mesAbv(m))+' ›</div><div class="v num '+(O.livre>=0?'restam':'passou')+'">'+brl0(Math.abs(O.livre))+'</div><div class="s"><b>'+(O.livre>=0?'restam':'passou')+'</b> · gasto '+brl0(O.tG)+' de '+brl0(O.tO)+(O.totP+O.totC>0?' · '+brl0(O.totP+O.totC)+' comprometido':'')+'</div></a>'+
    '<a class="card" href="#meta"><div class="k">Meta de sobra ›</div><div class="v num">'+(ps?brl0(ps.value)+'<span class="small muted">/mês</span>':'definir')+'</div><div class="s">'+(sb0?'o orçamento atual deixa '+brl0(sobraOrc):'quanto sobra por mês')+'</div></a>'+
    '<a class="card" href="#fixas"><div class="k">Contas fixas ›</div><div class="v num">'+brl0(fT)+'<span class="small muted">/mês</span></div><div class="s">'+(O.isCur||m<=hoje?'a pagar em '+esc(mesAbv(hoje))+': '+brl0(fT-fP):fa.length+' contas')+(fSug?' · '+fSug+' para conferir':'')+'</div></a>'+
    '<a class="card" href="#simular"><div class="k">Simular ›</div><div class="v" style="font-size:16px;line-height:1.3">E se…?</div><div class="s">cortes, aportes, quitação, veículo, viagem'+(nSim?' · '+nSim+(nSim===1?' cenário salvo':' cenários salvos'):'')+'</div></a>'+
   '</div>'+
   '<h2>Reservas</h2><p class="small muted" style="margin-top:-4px">Dinheiro guardado com objetivo e prazo. É diferente da meta de sobra, que é quanto sobra por mês.</p><div class="list">'+(goals||[]).map((g,i)=>'<div class="item" onclick="editGoal('+i+')"><div class="d" style="flex:1"><div class="t">'+esc(g.name)+' <span class="pill'+(g.status==='proposta'?' warn':'')+'" style="font-size:11px">'+esc(g.status)+'</span></div><div class="bar"><i style="width:'+Math.min(100,g.pct||0)+'%"></i></div><div class="s" style="white-space:normal">'+brl0(g.progresso)+' de '+brl0(g.target_amount)+(g.target_date?' até '+fmtD(g.target_date)+'/'+g.target_date.slice(0,4):'')+(g.monthly_contribution?' · guardar '+brl0(g.monthly_contribution)+'/mês':'')+'</div></div><div class="a num">'+(g.pct||0)+'%</div></div>').join('')+
   '<div class="item" onclick="editGoal(-1)"><div class="d"><div class="t" style="color:var(--acc)">+ Nova reserva</div></div></div></div>'+
   '<h2>Patrimônio</h2><details class="pat panel small"><summary class="row"><span class="muted">Patrimônio líquido (bens menos dívidas) ›</span><b class="num">'+brl0(n.patrimonio_liquido)+'</b></summary><div style="margin-top:8px">'+[['Conta + poupança',Number(n.conta_corrente)+Number(n.poupanca)],['Investimentos',n.investimentos],['Imóveis (avaliação do banco)',n.bens],['− Cartão utilizado',-Number(n.cartao_utilizado)],['− Saldo devedor dos financiamentos',-Number(n.financiamentos_saldo)]].map(([l,v])=>'<div class="row" style="padding:2px 0"><span class="muted">'+l+'</span><span class="num">'+brl0(v)+'</span></div>').join('')+((inv||[]).length?'<div class="muted" style="margin-top:4px">'+(inv||[]).map(i=>esc(i.subtype||i.type)+' '+brl0(i.balance)+(i.due_date?' (vence '+fmtD(i.due_date)+'/'+i.due_date.slice(0,4)+')':'')).join(' · ')+'</div>':'')+(Number(n.financiamentos_sem_saldo)>0?'<div class="muted" style="margin-top:4px">'+n.financiamentos_sem_saldo+' financiamento(s) sem saldo devedor informado (em Contas fixas).</div>':'')+'</div></details>'+
   '<p class="small muted">Projeções e propostas não são resultado garantido. Os valores reais vêm do banco; o que é “proposta” espera a sua decisão.</p></div>';
  bindMonth(rerender);
}
async function renderOrcamento(q){const _rt=RT;
  if(q.get('month'))S.month=q.get('month');const m=S.month;
  const O=await orcDados(m);const {B,MC,futuro,totP,totC,tO,tG,isCur,ritmo}=O;
  const fm={};O.fut.forEach(r=>{fm[r.competence_month]=(fm[r.competence_month]||0)+Number(r.valor)});const fk=Object.keys(fm).sort().slice(0,6);
  window._bud=B;window._budM=m;
  const bar=(g,o)=>{const p=o>0?Math.min(100,Math.round(g/o*100)):100;const over=o>0&&g>o*ritmo*1.1;return '<div class="bar"><i style="width:'+p+'%;background:'+(g>o&&o>0?'var(--neg)':over?'var(--warn)':'var(--acc)')+'"></i></div>'};
  const sl=(b)=>Number(b.saldo)-(futuro?(MC[b.group_id]?.p||0):0)-(MC[b.group_id]?.c||0);
  if(_rt!==RT)return;$('#app').innerHTML='<div class="wrap">'+voltar('Plano','#plano')+'<div class="row"><h1>Orçamento</h1>'+monthPicker(true)+'</div>'+
   '<div class="panel"><div class="row"><b>'+restaTxt(O.livre)+'</b><span class="pill'+(tG>tO?' bad':tG>tO*ritmo*1.1?' warn':'')+'">'+(tO?Math.round(tG/tO*100):0)+'% gasto</span></div>'+bar(tG,tO)+
    '<div class="small muted" style="margin-top:6px">Gasto '+brl0(tG)+' de '+brl0(tO)+(isCur?' · ritmo esperado hoje '+brl0(tO*ritmo):'')+'</div>'+
    ((totP+totC)>0?'<div class="small muted">'+(futuro?'Já comprometido':'Ainda comprometido')+': '+brl0(totP+totC)+' (parcelas do cartão '+brl0(totP)+(futuro?' a lançar':' já lançadas')+' · contas fixas '+(futuro?'previstas':'ainda não pagas')+' '+brl0(totC)+')</div>':'')+
    '<details class="small" style="margin-top:6px"><summary class="muted" style="cursor:pointer">Como é calculado</summary><p class="muted" style="margin:6px 0 0">Restam = orçado − gasto'+(futuro?'':' já feito')+' − contas fixas '+(futuro?'previstas':'ainda não pagas')+(futuro?' − parcelas do cartão a lançar':'')+'. Valores “proposta” = mediana de mai–out/26.</p></details></div>'+
   '<div class="list" style="margin-top:10px">'+B.map((b,i)=>'<div class="item" onclick="editBudget('+i+')"><div class="d" style="flex:1"><div class="t">'+esc(b.group_name)+(b.source==='proposta'?' <span class="pill" style="font-size:11px">proposta</span>':'')+'</div>'+bar(Number(b.gasto),Number(b.orcado))+'<div class="s">'+brl0(b.gasto)+' de '+brl0(b.orcado)+'</div>'+(MC[b.group_id]&&(MC[b.group_id].p+MC[b.group_id].c)>0?'<div class="s" style="white-space:normal">comprometido: '+(MC[b.group_id].p?brl0(MC[b.group_id].p)+' em '+MC[b.group_id].n+' parcela(s)'+(futuro?' a lançar':' já lançadas'):'')+(MC[b.group_id].p&&MC[b.group_id].c?' · ':'')+(MC[b.group_id].c?brl0(MC[b.group_id].c)+' de contas fixas ('+esc(MC[b.group_id].nomes)+')':'')+'</div>':'')+'</div><div class="a num small">'+restaTxt(sl(b))+'</div></div>').join('')+'</div>'+
   '<p class="small muted">Toque numa categoria para mudar o valor: só neste mês ou deste mês em diante. Escolha um mês futuro no seletor para ver o que já está comprometido nele.</p>'+
   '<h2>Parcelas futuras no cartão</h2><div class="list">'+(fk.length?fk.map(k=>'<a class="item" href="#orcamento?month='+k.slice(0,7)+'" style="text-decoration:none;color:inherit"><div class="d"><div class="t">'+mesNome(k.slice(0,7))+'</div></div><div class="a num">'+brl0(fm[k])+' ›</div></a>').join(''):'<div class="item">Nenhuma parcela futura.</div>')+'</div></div>';
  bindMonth(()=>{location.hash='orcamento?month='+S.month});
}
const num=(v)=>{let x=String(v??'').trim().replace(/^R\\$\\s*/,'').replace(/\\s/g,'');if(x==='')return null;if(x.includes(','))x=x.replace(/\\./g,'').replace(',','.');else if(/^-?\\d{1,3}(\\.\\d{3})+$/.test(x))x=x.replace(/\\./g,'');const n=Number(x);return isFinite(n)?n:null};
const mesesEntre=(a,b)=>{const out=[];for(let k=a;k<=b;k=addM(k,1))out.push(k);return out};
window.editBudget=(i)=>{const b=window._bud[i],m=window._budM||S.month;const fim=addM(mesAtual(),12);
  openSheet('<b>Orçamento · '+esc(b.group_name)+'</b><p class="small muted">Em '+mesNome(m)+': orçado '+brl(b.orcado)+(b.source==='proposta'?' (proposta)':'')+' · gasto '+brl(b.gasto)+'.</p><label class="small" for="bv">Novo valor mensal</label><input id="bv" inputmode="decimal" value="'+Math.round(b.orcado)+'">'+
   '<div class="bopt"><button onclick="saveBudget('+i+',&quot;mes&quot;)">Só em '+esc(mesAbv(m))+'</button><button class="ghost" onclick="saveBudget('+i+',&quot;diante&quot;)">De '+esc(mesAbv(m))+' em diante</button><button class="ghost" onclick="closeSheet()">Cancelar</button></div>'+
   '<p class="small muted">“Em diante” grava '+mesesEntre(m,fim).length+' meses ('+esc(mesAbv(m))+' a '+esc(mesAbv(fim))+') e passa a ser o valor padrão dos seguintes. Os meses anteriores continuam como estão.</p>')};
window.saveBudget=async(i,modo)=>{const b=window._bud[i],m=window._budM||S.month,g=b.group_id;const v=num($('#bv').value);if(v==null||v<0){toast('Valor inválido');return;}
  const now=new Date().toISOString();
  if(modo==='mes'){const {data:old}=await sb.from('budgets').select('amount,source').eq('group_id',g).eq('month',m+'-01').maybeSingle();
    const {error}=await sb.from('budgets').upsert({group_id:g,month:m+'-01',amount:v,source:'hugo',updated_at:now});if(error){toast('Não salvou: '+error.message);return;}
    closeSheet();toast(b.group_name+' em '+mesAbv(m)+': '+brl0(v),'Desfazer',async()=>{const r=old?await sb.from('budgets').upsert({group_id:g,month:m+'-01',amount:old.amount,source:old.source,updated_at:new Date().toISOString()}):await sb.from('budgets').delete().eq('group_id',g).eq('month',m+'-01');toast(r.error?'Não desfez: '+r.error.message:'Valor anterior restaurado');route()});route();return}
  const fim=addM(mesAtual(),12);const {data:def,error:e0}=await sb.from('budgets').select('amount,source').eq('group_id',g).eq('month','1900-01-01').maybeSingle();if(e0){toast('Não salvou: '+e0.message);return;}
  const antes=mesesEntre('2025-11',addM(m,-1));
  if(antes.length){const {error}=await sb.from('budgets').upsert(antes.map(k=>({group_id:g,month:k+'-01',amount:def?def.amount:0,source:def?def.source:'hugo',updated_at:now})),{onConflict:'group_id,month',ignoreDuplicates:true});if(error){toast('Não salvou: '+error.message);return;}}
  const rows=mesesEntre(m,fim).map(k=>({group_id:g,month:k+'-01',amount:v,source:'hugo',updated_at:now}));rows.push({group_id:g,month:'1900-01-01',amount:v,source:'hugo',updated_at:now});
  const {error}=await sb.from('budgets').upsert(rows,{onConflict:'group_id,month'});if(error){toast('Não salvou: '+error.message);return;}
  closeSheet();toast(b.group_name+': '+brl0(v)+' de '+mesAbv(m)+' em diante');route()};
window.editCom=(i)=>{const c=window._com[i];openSheet('<b>'+esc(c.name)+'</b><p class="small muted">'+esc(c.notes||'')+'</p><label class="small">Parcela mensal</label><input id="cm" inputmode="decimal" value="'+(c.monthly_amount??'')+'"><label class="small">Termina em</label><input id="ce" type="date" value="'+(c.end_date||'')+'">'+(c.kind==='financiamento'?'<label class="small">Saldo devedor hoje</label><input id="co" inputmode="decimal" value="'+(c.outstanding_balance??'')+'">':'')+'<div class="row" style="margin-top:10px"><button class="ghost" onclick="closeSheet()">Cancelar</button><button onclick="saveCom('+i+')">Salvar</button></div>')};
window.saveCom=async(i)=>{const c=window._com[i];const upd={monthly_amount:num($('#cm').value),end_date:$('#ce').value||null,source:'hugo',updated_at:new Date().toISOString()};if($('#co')){upd.outstanding_balance=num($('#co').value);upd.outstanding_at=new Date().toISOString().slice(0,10);}const {error}=await sb.from('commitments').update(upd).eq('id',c.id);if(error){toast('Não salvou: '+error.message);return;}if(upd.monthly_amount!=null&&Number(upd.monthly_amount)!==Number(c.monthly_amount)){const {data:fx}=await sb.from('fixed_expenses').select('id').eq('commitment_id',c.id);for(const x of (fx||[]))await sb.from('fixed_expense_values').upsert({fixed_expense_id:x.id,valid_from:mesAtual()+'-01',amount:upd.monthly_amount,note:'alterado em Contas fixas',created_by:S.member?.id},{onConflict:'fixed_expense_id,valid_from'});}closeSheet();toast('Financiamento atualizado');route();};
window.editGoal=(i)=>{const g=i>=0?window._goals[i]:{name:'',target_amount:'',target_date:'',monthly_contribution:'',progress_source:'manual',current_amount:0,status:'ativa'};
  openSheet('<b>'+(i>=0?'Reserva':'Nova reserva')+'</b><label class="small">Nome</label><input id="gn" value="'+esc(g.name)+'"><label class="small">Valor alvo</label><input id="gt" inputmode="decimal" value="'+(g.target_amount??'')+'"><label class="small">Prazo</label><input id="gd" type="date" value="'+(g.target_date||'')+'"><label class="small">Quanto guardar por mês</label><input id="ga" inputmode="decimal" value="'+(g.monthly_contribution??'')+'">'+
   '<label class="small">Progresso medido por</label><select id="gp"><option value="poupanca_investimentos"'+(g.progress_source==='poupanca_investimentos'?' selected':'')+'>Poupança + investimentos</option><option value="investimentos"'+(g.progress_source==='investimentos'?' selected':'')+'>Investimentos</option><option value="manual"'+(g.progress_source==='manual'?' selected':'')+'>Valor informado</option></select><label class="small">Valor já acumulado (se informado)</label><input id="gc" inputmode="decimal" value="'+(g.current_amount??0)+'">'+
   '<label class="small">Situação</label><select id="gs">'+['proposta','ativa','concluida','cancelada'].map(s=>'<option'+(s===g.status?' selected':'')+'>'+s+'</option>').join('')+'</select>'+
   '<div class="row" style="margin-top:10px"><button class="ghost" onclick="closeSheet()">Cancelar</button><button onclick="saveGoal('+i+')">Salvar</button></div>')};
window.saveGoal=async(i)=>{const row={name:$('#gn').value.trim(),target_amount:num($('#gt').value),target_date:$('#gd').value||null,monthly_contribution:num($('#ga').value),progress_source:$('#gp').value,current_amount:num($('#gc').value)||0,status:$('#gs').value,updated_at:new Date().toISOString()};
  if(!row.name||!row.target_amount){toast('Informe nome e valor alvo');return;}
  const q=i>=0?sb.from('goals').update(row).eq('id',window._goals[i].id):sb.from('goals').insert(row);const {error}=await q;if(error){toast('Não salvou: '+error.message);return;}closeSheet();toast('Reserva salva');route();};

// ---------- Simulações (item 13) — nada aqui grava dados reais ----------
const SIM_TIPOS={corte:'Reduzir gastos de uma categoria',renda:'Redução de renda',aporte:'Aumentar aporte mensal',quitacao:'Quitar dívida antecipadamente',veiculo:'Financiar um veículo',viagem:'Planejar uma viagem',inesperada:'Despesa inesperada',anual:'Gasto anual recorrente',adiar:'Mudar a data de um pagamento'};
let SIM={base:null,ajustes:[],rend:0,nome:''};
const addM=(ym0,k)=>{const d=new Date(Date.UTC(+ym0.slice(0,4),+ym0.slice(5,7)-1+k,1));return d.toISOString().slice(0,7)};
const pmt=(pv,i,n)=>i>0?pv*i/(1-Math.pow(1+i,-n)):pv/n;
function grupoDe(cat){const c=S.cats.find(x=>x.id===cat);return c?(c.parent_id||c.id):cat}
function projetar(base,ajustes,rend){
  const m0=base.mes_base.slice(0,7);const N=12;const out=[];
  let liq=Number(base.liquidez_imediata)-Number(base.fatura_fechada_a_pagar||0), inv=Number(base.investimentos), divNova=0, bens=0, divQuit=0;
  const grupos=(base.despesas_grupo||[]).map(g=>({...g,mediana:Number(g.mediana)}));
  const comp=(base.compromissos||[]);
  const quitados={};ajustes.filter(a=>a.t==='quitacao').forEach(a=>{quitados[a.id]=a.mes});
  const veic=ajustes.filter(a=>a.t==='veiculo').map(a=>({...a,saldo:Math.max(0,a.valor-a.entrada),parc:pmt(Math.max(0,a.valor-a.entrada),a.taxa/100,a.prazo)}));
  for(let k=0;k<N;k++){
    const mes=addM(m0,k);let rec=Number(base.receita_mensal);let desp=0;let extra=0;let aporte=0;let notas=[];
    ajustes.filter(a=>a.t==='renda'&&mes>=a.desde).forEach(a=>{rec*=1-a.pct/100});
    for(const g of grupos){let v=g.mediana;
      comp.forEach(c=>{if(grupoDe(c.categoria)!==g.group_id)return;const fim=c.fim?c.fim.slice(0,7):null;
        if((fim&&mes>fim)||(quitados[c.id]&&mes>quitados[c.id]))v-=Number(c.parcela||0)});
      ajustes.filter(a=>a.t==='corte'&&a.grupo===g.group_id&&mes>=a.desde).forEach(a=>{v*=1-a.pct/100});
      desp+=Math.max(0,v)}
    ajustes.forEach(a=>{
      if(a.t==='aporte'&&mes>=a.desde)aporte+=a.valor;
      if(a.t==='quitacao'&&mes===a.mes){extra+=a.valor;divQuit+=a.valor}
      if(a.t==='viagem'){for(let p=0;p<a.parcelas;p++)if(addM(a.mes,p)===mes)extra+=a.valor/a.parcelas}
      if(a.t==='inesperada'&&mes===a.mes)extra+=a.valor;
      if(a.t==='anual'&&mes.slice(5,7)===a.mes.slice(5,7))extra+=a.valor;
      if(a.t==='adiar'){if(mes===a.de)extra-=a.valor;if(mes===a.para)extra+=a.valor}});
    veic.forEach(v=>{if(mes===v.mes){extra+=v.entrada;bens+=v.valor;divNova+=v.saldo}
      if(mes>v.mes&&v.saldo>0.005){const j=v.saldo*v.taxa/100;const am=Math.min(v.saldo,v.parc-j);extra+=v.parc;v.saldo-=am;divNova-=am}});
    const rendM=inv*rend/100;inv+=rendM+aporte;liq+=rec-desp-extra-aporte;
    out.push({mes,rec,desp:desp+extra,aporte,res:rec-desp-extra,liq,inv,pat:liq+inv+bens-divNova-(Number(base.cartao_utilizado)-Number(base.fatura_fechada_a_pagar||0))-Number(base.financiamentos_saldo||0)+divQuit});
  }
  return out}
async function renderSimular(){
  if(!SIM.base){const {data,error}=await sb.from('v_sim_base').select('*').maybeSingle();if(error){toast(error.message);return;}SIM.base=data;}
  const {data:salvos}=await sb.from('sim_scenarios').select('*').order('created_at',{ascending:false});window._salvos=salvos||[];
  const b=SIM.base;const base=projetar(b,[],SIM.rend);const cen=projetar(b,SIM.ajustes,SIM.rend);
  const soma=(a,f)=>a.reduce((s,x)=>s+f(x),0);
  const dRes=soma(cen,x=>x.res)-soma(base,x=>x.res);
  const afet=cen.findIndex((x,i)=>Math.abs(x.liq-base[i].liq)>0.5);
  const imed=afet>=0?(cen[afet].liq-(afet?cen[afet-1].liq:Number(b.liquidez_imediata)-Number(b.fatura_fechada_a_pagar||0)))-(base[afet].liq-(afet?base[afet-1].liq:Number(b.liquidez_imediata)-Number(b.fatura_fechada_a_pagar||0))):0;
  const minC=Math.min(...cen.map(x=>x.liq)),minB=Math.min(...base.map(x=>x.liq));
  const negC=cen.filter(x=>x.liq<0).map(x=>x.mes),resNeg=cen.filter(x=>x.res<0).length;
  const riscos=[];
  if(negC.length)riscos.push('Conta + poupança ficam negativas em '+negC.length+' de 12 meses (primeiro: '+mesNome(negC[0])+'). Na prática isso significa cheque especial ou resgate de aplicações.');
  if(resNeg)riscos.push(resNeg+' meses com resultado negativo (despesas maiores que receitas).');
  if(SIM.ajustes.some(a=>a.t==='veiculo'))riscos.push('O veículo perde valor com o tempo; a simulação mantém o valor de compra e não inclui IPVA, seguro e manutenção.');
  if(SIM.ajustes.some(a=>a.t==='quitacao'))riscos.push('Confira no contrato o valor exato de quitação e se há desconto de juros; o saldo devedor informado é o usado aqui.');
  if(SIM.rend>0)riscos.push('Rendimento de '+SIM.rend+'% a.m. é suposição; aplicações podem render menos.');
  riscos.push('Receita e despesas usam a mediana dos últimos 6 meses; meses atípicos (viagens, férias, 13º, impostos) não estão previstos.');
  const premissas=['Receita mensal: '+brl0(b.receita_mensal)+' (mediana de 6 meses)','Despesas por categoria: mediana de 6 meses ('+brl0(soma(b.despesas_grupo||[],g=>Number(g.mediana)))+'/mês), descontando compromissos que terminam (carro 11/2026, seguro 12/2026)','Ponto de partida: conta + poupança '+brl0(b.liquidez_imediata)+' menos a fatura fechada a pagar '+brl0(b.fatura_fechada_a_pagar)+'; investimentos '+brl0(b.investimentos),'Rendimento das aplicações: '+SIM.rend+'% ao mês'].concat(SIM.ajustes.map(descAjuste));
  const row=(l,v,cls)=>'<div class="item"><div class="d"><div class="t" style="white-space:normal">'+l+'</div></div><div class="a num '+(cls||'')+'">'+v+'</div></div>';
  const sinal=(v)=>(v>=0?'+':'−')+brl0(Math.abs(v)).replace('-','');
  $('#app').innerHTML='<div class="wrap">'+voltar('Plano','#plano')+'<div class="row"><h1>Simulações</h1></div>'+
   '<p class="small muted">Monte um cenário juntando um ou mais ajustes. Nada aqui altera os dados reais. Projeção de 12 meses a partir de '+mesNome(b.mes_base.slice(0,7))+'.</p>'+
   '<div class="panel"><div class="row"><b>Ajustes do cenário</b><button onclick="novoAjuste()" style="padding:7px 12px">+ Ajuste</button></div>'+
   (SIM.ajustes.length?SIM.ajustes.map((a,i)=>'<div class="row small" style="margin-top:8px"><span>'+esc(descAjuste(a))+'</span><a href="#" onclick="event.preventDefault();SIM.ajustes.splice('+i+',1);renderSimular()">remover</a></div>').join(''):'<p class="small muted">Nenhum ajuste: mostrando só o cenário base.</p>')+
   '<div class="row" style="margin-top:10px"><label class="small">Rendimento das aplicações (% a.m.)</label><input id="rend" inputmode="decimal" style="width:90px" value="'+String(SIM.rend).replace('.',',')+'"></div></div>'+
   '<h2>O que muda</h2><div class="list">'+
    row('Impacto imediato'+(afet>=0?' ('+mesNome(cen[afet].mes)+')':''),sinal(imed),imed<0?'neg':'pos')+
    row('Impacto mensal recorrente (sobra de '+mesNome(cen[11].mes)+' × base)',sinal(cen[11].res-base[11].res),(cen[11].res-base[11].res)<0?'neg':'pos')+
    row('Impacto em 12 meses',sinal(dRes),dRes<0?'neg':'pos')+
    row('Conta + poupança em '+mesNome(cen[11].mes)+' (base '+brl0(base[11].liq)+')',brl0(cen[11].liq),cen[11].liq<0?'neg':'')+
    row('Pior mês de liquidez (base '+brl0(minB)+')',brl0(minC),minC<0?'neg':'')+
    row('Investimentos em '+mesNome(cen[11].mes)+' (base '+brl0(base[11].inv)+')',brl0(cen[11].inv))+
    row('Patrimônio financeiro em '+mesNome(cen[11].mes)+' (base '+brl0(base[11].pat)+')',brl0(cen[11].pat),cen[11].pat<0?'neg':'pos')+'</div>'+
   '<h2>Mês a mês (cenário × base)</h2><div class="panel" style="overflow-x:auto;padding:8px"><table class="small num" style="width:100%;border-collapse:collapse;min-width:330px"><tr class="muted"><td>Mês</td><td style="text-align:right">Sobrou</td><td style="text-align:right">Base</td><td style="text-align:right">Conta+poup.</td></tr>'+
    cen.map((x,i)=>'<tr style="border-top:1px solid var(--line)"><td>'+x.mes.slice(5,7)+'/'+x.mes.slice(2,4)+'</td><td style="text-align:right" class="'+(x.res<0?'neg':'')+'">'+brl0(x.res)+'</td><td style="text-align:right" class="muted">'+brl0(base[i].res)+'</td><td style="text-align:right" class="'+(x.liq<0?'neg':'')+'">'+brl0(x.liq)+'</td></tr>').join('')+'</table></div>'+
   '<h2>Premissas</h2><div class="panel small">'+premissas.map(p=>'<div style="margin:3px 0">• '+esc(p)+'</div>').join('')+'</div>'+
   '<h2>Riscos</h2><div class="panel small">'+riscos.map(p=>'<div style="margin:3px 0">• '+esc(p)+'</div>').join('')+'</div>'+
   '<p class="small muted">Projeção é estimativa, não resultado garantido.</p>'+
   '<div class="row" style="margin:12px 0"><input id="snome" placeholder="nome do cenário" value="'+esc(SIM.nome)+'"><button onclick="salvarCen()" style="white-space:nowrap">Salvar cenário</button></div>'+
   ((salvos||[]).length?'<h2>Cenários salvos</h2><div class="list">'+(salvos||[]).map((s,i)=>'<div class="item" onclick="abrirCen('+i+')"><div class="d"><div class="t">'+esc(s.name)+'</div><div class="s">'+(s.params.ajustes||[]).length+' ajuste(s) · '+new Date(s.created_at).toLocaleDateString('pt-BR')+'</div></div><span class="muted">›</span></div>').join('')+'</div>':'')+
   '</div>';
  $('#rend').onchange=(e)=>{SIM.rend=num(e.target.value)||0;renderSimular()};
}
function descAjuste(a){const g=(id)=>((SIM.base.despesas_grupo||[]).find(x=>x.group_id===id)||{}).nome||id;const c=(id)=>((SIM.base.compromissos||[]).find(x=>x.id===id)||{}).nome||'';const M=(m)=>m.slice(5,7)+'/'+m.slice(0,4);
  return {corte:()=>'Reduzir '+a.pct+'% em '+g(a.grupo)+' a partir de '+M(a.desde),renda:()=>'Renda '+a.pct+'% menor a partir de '+M(a.desde),aporte:()=>'Aportar '+brl0(a.valor)+'/mês a partir de '+M(a.desde),
   quitacao:()=>'Quitar '+c(a.id)+' em '+M(a.mes)+' por '+brl0(a.valor),veiculo:()=>'Veículo de '+brl0(a.valor)+', entrada '+brl0(a.entrada)+', '+a.prazo+'x a '+String(a.taxa).replace('.',',')+'% a.m. ('+brl0(pmt(a.valor-a.entrada,a.taxa/100,a.prazo))+'/mês) em '+M(a.mes),
   viagem:()=>'Viagem de '+brl0(a.valor)+' em '+a.parcelas+'x a partir de '+M(a.mes),inesperada:()=>'Despesa inesperada de '+brl0(a.valor)+' em '+M(a.mes),anual:()=>'Gasto anual de '+brl0(a.valor)+' todo mês '+a.mes.slice(5,7),adiar:()=>'Pagamento de '+brl0(a.valor)+' passa de '+M(a.de)+' para '+M(a.para)}[a.t]()}
window.novoAjuste=()=>{openSheet('<b>Novo ajuste</b><select id="at">'+Object.entries(SIM_TIPOS).map(([k,v])=>'<option value="'+k+'">'+v+'</option>').join('')+'</select><div id="af" style="margin-top:8px"></div><div class="row" style="margin-top:10px"><button class="ghost" onclick="closeSheet()">Cancelar</button><button onclick="salvarAjuste()">Adicionar</button></div>');$('#at').onchange=formAjuste;formAjuste()};
function formAjuste(){const t=$('#at').value,b=SIM.base,m1=addM(b.mes_base.slice(0,7),1);const mesSel=(id,v)=>'<input id="'+id+'" type="month" value="'+(v||m1)+'">';const inp=(id,l,v)=>'<label class="small">'+l+'</label><input id="'+id+'" inputmode="decimal" value="'+(v??'')+'">';
  const grupos='<label class="small">Categoria</label><select id="ag">'+(b.despesas_grupo||[]).map(g=>'<option value="'+g.group_id+'">'+esc(g.nome)+' ('+brl0(g.mediana)+'/mês)</option>').join('')+'</select>';
  $('#af').innerHTML={corte:grupos+inp('ap','Redução (%)',15)+'<label class="small">A partir de</label>'+mesSel('am'),renda:inp('ap','Redução da renda (%)',10)+'<label class="small">A partir de</label>'+mesSel('am'),aporte:inp('av','Aporte mensal (R$)',3000)+'<label class="small">A partir de</label>'+mesSel('am'),
   quitacao:'<label class="small">Dívida</label><select id="ac">'+(b.compromissos||[]).filter(c=>c.tipo!=='fixo').map(c=>'<option value="'+c.id+'">'+esc(c.nome)+'</option>').join('')+'</select>'+inp('av','Valor para quitar (R$)',((b.compromissos||[]).find(c=>c.tipo==='financiamento'&&c.saldo_devedor)||{}).saldo_devedor||'')+'<label class="small">Mês</label>'+mesSel('am'),
   veiculo:inp('av','Valor do veículo (R$)',150000)+inp('ae','Entrada (R$)',50000)+inp('ax','Juros (% ao mês)','1,6')+inp('an','Parcelas',48)+'<label class="small">Mês da compra</label>'+mesSel('am'),
   viagem:inp('av','Custo total (R$)',20000)+inp('an','Parcelas',1)+'<label class="small">Mês</label>'+mesSel('am'),inesperada:inp('av','Valor (R$)',10000)+'<label class="small">Mês</label>'+mesSel('am'),
   anual:inp('av','Valor (R$)',5000)+'<label class="small">Mês em que ocorre</label>'+mesSel('am'),adiar:inp('av','Valor (R$)',5000)+'<label class="small">De</label>'+mesSel('ad')+'<label class="small">Para</label>'+mesSel('am',addM(m1,2))}[t]}
window.salvarAjuste=()=>{const t=$('#at').value,v=(id)=>num($('#'+id).value),s=(id)=>$('#'+id).value;let a;
  ({corte:()=>a={t,grupo:s('ag'),pct:v('ap'),desde:s('am')},renda:()=>a={t,pct:v('ap'),desde:s('am')},aporte:()=>a={t,valor:v('av'),desde:s('am')},quitacao:()=>a={t,id:s('ac'),valor:v('av'),mes:s('am')},
   veiculo:()=>a={t,valor:v('av'),entrada:v('ae')||0,taxa:v('ax')||0,prazo:Math.max(1,Math.round(v('an')||1)),mes:s('am')},viagem:()=>a={t,valor:v('av'),parcelas:Math.max(1,Math.round(v('an')||1)),mes:s('am')},
   inesperada:()=>a={t,valor:v('av'),mes:s('am')},anual:()=>a={t,valor:v('av'),mes:s('am')},adiar:()=>a={t,valor:v('av'),de:s('ad'),para:s('am')}})[t]();
  const nums=Object.entries(a).filter(([k,x])=>typeof x==='number'||x===null);if(nums.some(([k,x])=>x==null||!isFinite(x))||Object.values(a).some(x=>x==='')){toast('Preencha todos os campos');return;}
  SIM.ajustes.push(a);closeSheet();renderSimular()};
window.salvarCen=async()=>{const name=$('#snome').value.trim();if(!name){toast('Dê um nome ao cenário');return;}if(!SIM.ajustes.length){toast('Adicione ao menos um ajuste');return;}
  const {error}=await sb.from('sim_scenarios').insert({name,params:{ajustes:SIM.ajustes,rend:SIM.rend},created_by:S.member?.id});if(error){toast('Não salvou: '+error.message);return;}SIM.nome=name;toast('Cenário salvo');renderSimular()};
window.abrirCen=(i)=>{const s=window._salvos[i];SIM.ajustes=JSON.parse(JSON.stringify(s.params.ajustes||[]));SIM.rend=s.params.rend||0;SIM.nome=s.name;renderSimular();window.scrollTo(0,0)};
window.SIM=SIM;window.renderSimular=renderSimular;window.toast=toast;

// ---------- Meta de sobra mensal (receita − fixas − parcelas = margem; corte não linear só no variável) ----------
const CLASSES={fixa:{n:'Fixa',max:0},essencial:{n:'Essencial',max:10},ajustavel:{n:'Ajustável',max:30},discricionaria:{n:'Dá para cortar',max:50}};
let MT=null;
async function renderMeta(){
  if(!MT){
    const m0=mesAtual();
    const [{data:sim},{data:base},{data:flex},{data:ps},{data:gl},{data:fx},{data:mc}]=await Promise.all([sb.from('v_sim_base').select('receita_mensal').maybeSingle(),sb.from('v_meta_base').select('*'),sb.from('category_flex').select('*'),sb.from('plan_settings').select('*').eq('key','sobra_meta').maybeSingle(),sb.from('goals').select('*').neq('status','cancelada'),sb.from('v_fixed_month').select('month,group_id,devido').gte('month',m0+'-01'),sb.from('v_month_commitments').select('month,group_id,parcelas_cartao').gte('month',m0+'-01')]);
    const {data:its}=await sb.from('v_meta_items').select('*').order('total_6m',{ascending:false});
    if(!sim){toast('Sem base de cálculo');return;}
    const meses=[];for(let k=0;k<13;k++)meses.push(addM(m0,k));
    const G={};const g=(id)=>G[id]||(G[id]={id,nome:(S.cats.find(c=>c.id===id)||{}).name||id,var:0,fix:{},parc:{},hist:{}});
    (base||[]).forEach(b=>{const r=g(b.group_id);r.nome=b.nome||r.nome;r.var=Math.round(Number(b.variavel_mediana));r.hist=b.variavel_por_mes||{}});
    (fx||[]).forEach(f=>{const r=g(f.group_id);const k=f.month.slice(0,7);r.fix[k]=(r.fix[k]||0)+Number(f.devido||0)});
    (mc||[]).forEach(p=>{const r=g(p.group_id);const k=p.month.slice(0,7);r.parc[k]=(r.parc[k]||0)+Number(p.parcelas_cartao||0)});
    Object.values(G).forEach(r=>{const f=(flex||[]).find(x=>x.group_id===r.id)||{classe:'ajustavel',max_cut_pct:30};r.classe=f.classe;r.max=Number(f.max_cut_pct)});
    MT={rec:Number(sim.receita_mensal),meta:Number(ps?.value??10000),rows:Object.values(G).filter(r=>r.var>0||meses.some(k=>(r.fix[k]||0)+(r.parc[k]||0)>0)),goals:gl||[],meses,mes:meses.includes(S.month)?S.month:m0,man:{},todos:false,items:its||[],open:{},all:{}};
    MT.rows.sort((a,b)=>(b.var+(b.fix[m0]||0))-(a.var+(a.fix[m0]||0)));
  }
  desenharMeta();
}
function calcMes(k){const R=MT.rows;const F=R.reduce((s,r)=>s+(r.fix[k]||0),0),P=R.reduce((s,r)=>s+(r.parc[k]||0),0);
  const margem=MT.rec-F-P,disp=margem-MT.meta,V=R.reduce((s,r)=>s+r.var,0),cap=R.reduce((s,r)=>s+r.var*r.max/100,0);
  const need=Math.max(0,V-disp),f=cap>0?Math.min(1,need/cap):0;const man=MT.man[k]||{};
  const novo={};R.forEach(r=>{novo[r.id]=man[r.id]!=null?man[r.id]:Math.round(r.var-r.var*r.max/100*f)});
  const N=R.reduce((s,r)=>s+novo[r.id],0);
  return {k,F,P,margem,disp,V,cap,need,novo,N,sobra:margem-N,sobraMax:margem-(V-cap)}}
function mtItens(r){const L=MT.items.filter(it=>it.group_id===r.id&&(Number(it.total_6m)>0||Number(it.mes_atual)>0));const tot=L.reduce((s,it)=>s+Number(it.media_6m),0);const at=L.reduce((s,it)=>s+Number(it.mes_atual),0);
  const show=MT.all[r.id]?L:L.slice(0,12);const ma=mesNome(mesAtual()).split(' ')[0];
  return '<div style="margin-top:6px;border-top:1px solid var(--line)"><div class="row small muted" style="padding:6px 0 2px"><span>Recebedor (últimos 6 meses)</span><span>média/mês · '+ma+'</span></div>'+
   show.map(it=>'<div class="row small" style="padding:5px 0;border-top:1px dashed var(--line)"><span style="min-width:0"><a href="#lancamentos?all=1&search='+encodeURIComponent(String(it.payee||'').split(' ').slice(0,2).join(' '))+'">'+esc(it.payee)+'</a><br><span class="muted">'+esc(it.category_name||'')+' · '+({conta:'conta',cartao:'cartão',ambos:'conta e cartão'}[it.canal]||'')+' · '+it.meses+'/6 meses · '+it.n+' lanç.'+(tot>0?' · '+Math.round(Number(it.media_6m)/tot*100)+'% da categoria':'')+'</span></span><span class="num" style="white-space:nowrap;text-align:right">'+brl0(it.media_6m)+'<br><span class="muted">'+(Number(it.mes_atual)?brl0(it.mes_atual):'—')+'</span></span></div>').join('')+
   (L.length>12?'<div class="small" style="padding:6px 0"><a href="#" onclick="event.preventDefault();mtTodos(\\''+r.id+'\\')">'+(MT.all[r.id]?'mostrar só os 12 maiores':'mostrar todos ('+L.length+')')+'</a></div>':'')+
   '<div class="row small" style="padding:6px 0;border-top:1px solid var(--line)"><b>Total</b><b class="num" style="text-align:right">'+brl0(tot)+'<br><span class="muted">'+brl0(at)+'</span></b></div><div class="small muted">Média/mês = total dos últimos 6 meses ÷ 6 (soma bate com a média da categoria; o “habitual” usa a mediana dos meses). Sem despesas fixas cadastradas e sem compras parceladas (essas aparecem na linha de parcelas do mês em que caem). Toque no nome para ver os lançamentos.</div></div>'}
window.mtAbrir=(id)=>{MT.open[id]=!MT.open[id];desenharMeta()};window.mtTodos=(id)=>{MT.all[id]=!MT.all[id];desenharMeta()};
function desenharMeta(){
  const c=calcMes(MT.mes);const falta=MT.meta-c.sobra;const M=(k)=>k.slice(5,7)+'/'+k.slice(2,4);
  const linhaV=(l,v,cls,b)=>'<div class="row small" style="padding:3px 0'+(b?';border-top:1px solid var(--line);margin-top:3px;padding-top:6px':'')+'"><span>'+l+'</span><b class="num '+(cls||'')+'">'+v+'</b></div>';
  const linha=(r)=>{const i=MT.rows.indexOf(r);const fx=r.fix[MT.mes]||0,pc=r.parc[MT.mes]||0,nv=c.novo[r.id];const corte=r.var-nv;
    return '<div class="item" style="display:block"><div class="row"><div class="d"><div class="t">'+esc(r.nome)+'</div><div class="s" style="white-space:normal">'+(fx?'fixas '+brl0(fx)+' · ':'')+(pc?'parcelas '+brl0(pc)+' · ':'')+'variável habitual '+brl0(r.var)+'</div></div><div class="a num">'+brl0(fx+pc+nv)+'</div></div>'+
     (r.var>0?'<div style="display:grid;grid-template-columns:1.4fr .8fr 1.2fr;gap:6px;margin-top:6px"><select onchange="mtClasse('+i+',this.value)" style="padding:7px">'+Object.entries(CLASSES).map(([k,v])=>'<option value="'+k+'"'+(k===r.classe?' selected':'')+'>'+v.n+'</option>').join('')+'</select>'+
     '<input inputmode="decimal" style="padding:7px" value="'+r.max+'" onchange="mtMax('+i+',this.value)" title="corte máximo % do variável">'+
     '<input inputmode="decimal" style="padding:7px" value="'+nv+'" onchange="mtNovo('+i+',this.value)" title="orçamento variável do mês"></div>'+
     '<div class="small muted" style="margin-top:4px">variável: '+brl0(nv)+(corte>=1?' (<span class="pos">−'+brl0(corte).replace('-','')+'</span>)':'')+' · últimos 6 meses: '+Object.entries(r.hist).map(([m,v])=>M(m)+' '+brl0(v)).join(' · ')+'</div><div class="small" style="margin-top:4px"><a href="#" onclick="event.preventDefault();mtAbrir(\\''+r.id+'\\')">'+(MT.open[r.id]?'ocultar gastos ▴':'ver gastos ('+MT.items.filter(it=>it.group_id===r.id).length+') ▾')+'</a></div>'+(MT.open[r.id]?mtItens(r):''):'<div class="small muted" style="margin-top:4px">só despesas fixas e parcelas neste mês</div>')+'</div>'};
  const cab='<div class="small muted" style="display:grid;grid-template-columns:1.4fr .8fr 1.2fr;gap:6px;padding:6px 14px 0"><span>Classe</span><span>Até quanto cortar (%)</span><span>Variável R$</span></div>';
  const rv=MT.rows.filter(r=>r.var>0),rf=MT.rows.filter(r=>r.var<=0);
  $('#app').innerHTML='<div class="wrap"><div class="row"><h1>Meta de sobra</h1><select id="mm">'+MT.meses.map(k=>'<option value="'+k+'"'+(k===MT.mes?' selected':'')+'>'+mesNome(k)+'</option>').join('')+'</select></div>'+
   '<p class="small" style="margin:-4px 0 10px">'+voltar('Plano','#plano')+' · <a href="#fixas">Contas fixas</a></p>'+
   '<div class="panel"><div class="row"><label><b>Sobra mensal desejada</b><br><span class="small muted">vai para a reserva</span></label><input id="mmeta" inputmode="decimal" style="width:130px;text-align:right" value="'+MT.meta+'"></div>'+
   '<div style="margin-top:10px">'+linhaV('Receita (mediana de 6 meses)',brl0(MT.rec),'pos')+linhaV('− Contas fixas cadastradas ('+M(MT.mes)+')',brl0(-c.F),'neg')+linhaV('− Parcelas de compras parceladas no cartão',brl0(-c.P),'neg')+
    linhaV('= Livre depois das contas fixas',brl0(c.margem),c.margem<0?'neg':'',1)+linhaV('− Sobra desejada',brl0(-MT.meta),'neg')+linhaV('= Livre para o dia a dia',brl0(c.disp),c.disp<0?'neg':'pos',1)+linhaV('Gasto do dia a dia habitual (mediana)',brl0(c.V),'')+'</div>'+
   '<div class="kpis" style="margin:10px 0 0"><div class="kpi"><div class="v num '+(falta>0.5?'neg':'pos')+'">'+brl0(c.sobra)+'</div><div class="l">Sobra com este plano</div></div><div class="kpi"><div class="v num">'+brl0(c.sobraMax)+'</div><div class="l">Sobra máxima possível</div></div><div class="kpi"><div class="v num">'+brl0(c.V-c.N)+'</div><div class="l">Corte no dia a dia</div></div></div>'+
   '<p class="small" style="margin:10px 0 0">'+(falta>0.5?'<span class="neg">Faltam '+brl0(falta)+' para a meta em '+mesNome(MT.mes)+'.</span>'+(MT.meta>c.sobraMax+0.5?' Com os limites atuais a meta não é alcançável neste mês: aumente o corte máximo de alguma categoria, reduza a meta ou revise as despesas fixas.':' Toque em “Distribuir pela meta” ou ajuste os valores.'):'<span class="pos">Meta atingida em '+mesNome(MT.mes)+(falta<-0.5?' com '+brl0(-falta)+' de folga':'')+'.</span>')+'</p>'+
   '<div class="row" style="margin-top:10px;flex-wrap:wrap"><button class="ghost" onclick="mtDistribuir()">Distribuir pela meta</button><label class="chk"><input type="checkbox" id="mtodos"'+(MT.todos?' checked':'')+'> aplicar até '+mesNome(MT.meses[MT.meses.length-1])+'</label><button onclick="mtAdotar()">Adotar no orçamento</button></div></div>'+
   '<h2>Próximos meses</h2><div class="panel" style="overflow-x:auto;padding:8px"><table class="small num" style="width:100%;border-collapse:collapse;min-width:420px"><tr class="muted"><td>Mês</td><td style="text-align:right">Fixas</td><td style="text-align:right">Parcelas</td><td style="text-align:right">Margem</td><td style="text-align:right">Dia a dia</td><td style="text-align:right">Sobra</td></tr>'+
    MT.meses.map(k=>{const x=calcMes(k);return '<tr style="border-top:1px solid var(--line);cursor:pointer'+(k===MT.mes?';background:var(--acc2)':'')+'" onclick="mtMes(\\''+k+'\\')"><td>'+M(k)+'</td><td style="text-align:right">'+brl0(x.F)+'</td><td style="text-align:right">'+brl0(x.P)+'</td><td style="text-align:right">'+brl0(x.margem)+'</td><td style="text-align:right">'+brl0(x.N)+'</td><td style="text-align:right" class="'+(x.sobra<MT.meta-0.5?'neg':'pos')+'">'+brl0(x.sobra)+'</td></tr>'}).join('')+'</table><p class="small muted" style="margin:6px 4px 0">Toque num mês para detalhar. “Dia a dia” usa os cortes atuais, redistribuídos em cada mês.</p></div>'+
   '<h2>Gastos do dia a dia · '+mesNome(MT.mes)+'</h2><div class="list">'+cab+rv.map(linha).join('')+'<div class="item"><div class="d"><div class="t">Subtotal dia a dia</div><div class="s">habitual '+brl0(c.V)+'</div></div><div class="a num">'+brl0(c.N)+'</div></div></div>'+
   (rf.length?'<h2>Só fixas e parcelas</h2><div class="list">'+rf.map(linha).join('')+'</div>':'')+
   '<p class="small muted">Contas fixas: valor vigente no mês, conforme o cadastro. Parcelas: valor real das compras parceladas que caem na fatura do mês (todas as parcelas, inclusive a 1ª). Dia a dia habitual: mediana dos últimos 6 meses de cada categoria, sem despesas fixas e sem nenhuma compra parcelada — o parcelado só entra nos meses em que de fato cai, nunca como média. O corte é repartido só no dia a dia, na proporção do espaço de cada categoria (habitual × corte máximo). “Adotar” grava o orçamento do mês (fixas + parcelas + dia a dia) por categoria; os lançamentos reais não mudam. Projeção não é resultado garantido.</p></div>';
  $('#mmeta').onchange=(e)=>{MT.meta=num(e.target.value)||0;MT.man={};desenharMeta()};
  $('#mm').onchange=(e)=>{MT.mes=e.target.value;desenharMeta()};
  $('#mtodos').onchange=(e)=>{MT.todos=e.target.checked};
}
window.mtMes=(k)=>{MT.mes=k;desenharMeta();window.scrollTo(0,0)};
window.mtClasse=(i,c)=>{MT.rows[i].classe=c;MT.rows[i].max=CLASSES[c].max;MT.man={};desenharMeta()};
window.mtMax=(i,v)=>{MT.rows[i].max=Math.max(0,Math.min(100,num(v)||0));MT.man={};desenharMeta()};
window.mtNovo=(i,v)=>{const r=MT.rows[i];(MT.man[MT.mes]=MT.man[MT.mes]||{})[r.id]=Math.max(0,Math.round(num(v)||0));desenharMeta()};
window.mtDistribuir=()=>{delete MT.man[MT.mes];desenharMeta();toast('Corte redistribuído')};
window.mtAdotar=()=>{const ks=MT.todos?MT.meses.filter(k=>k>=MT.mes):[MT.mes];const n=ks.length*MT.rows.length;
  openSheet('<b>Adotar este orçamento?</b><p class="small">Vai gravar <b>'+n+' valores de orçamento</b> ('+MT.rows.length+' categorias × '+ks.length+(ks.length>1?' meses, de '+esc(mesNome(ks[0]))+' a '+esc(mesNome(ks[ks.length-1])):' mês, '+esc(mesNome(ks[0])))+'), substituindo os que existirem nesses meses, e a meta de sobra de '+brl0(MT.meta)+' por mês.</p><p class="small muted">Os lançamentos não mudam. Dá para ajustar os valores depois no Plano.</p><div class="row" style="margin-top:12px"><button class="ghost" onclick="closeSheet()">Cancelar</button><button onclick="mtAdotarExec()">Gravar orçamento</button></div>')};
window.mtAdotarExec=async()=>{closeSheet();const now=new Date().toISOString();const ks=MT.todos?MT.meses.filter(k=>k>=MT.mes):[MT.mes];
  const rows=[];ks.forEach(k=>{const x=calcMes(k);MT.rows.forEach(r=>rows.push({group_id:r.id,month:k+'-01',amount:Math.round((r.fix[k]||0)+(r.parc[k]||0)+x.novo[r.id]),source:'hugo',basis:{metodo:'meta de sobra mensal',meta:MT.meta,fixas:Math.round(r.fix[k]||0),parcelas:Math.round(r.parc[k]||0),dia_a_dia:x.novo[r.id],habitual:r.var,classe:r.classe,corte_max:r.max},updated_at:now}))});
  const r1=await sb.from('budgets').upsert(rows);
  const r2=await sb.from('category_flex').upsert(MT.rows.filter(r=>r.var>0).map(r=>({group_id:r.id,classe:r.classe,max_cut_pct:r.max,source:'hugo',updated_at:now})));
  const r3=await sb.from('plan_settings').upsert({key:'sobra_meta',value:MT.meta,updated_at:now,updated_by:S.member?.id});
  const res=MT.goals.find(g=>/reserva/i.test(g.name));let r4={};if(res)r4=await sb.from('goals').update({monthly_contribution:MT.meta,updated_at:now}).eq('id',res.id);
  const err=[r1,r2,r3,r4].map(r=>r.error).find(Boolean);if(err){toast('Não salvou: '+err.message);return;}
  toast(ks.length>1?'Orçamento adotado para '+ks.length+' meses':'Orçamento de '+mesNome(MT.mes)+' adotado');S.month=MT.mes;MT=null;location.hash='plano'};

// ---------- Despesas fixas (cadastro + histórico de valores) ----------
const normTxt=(s)=>String(s||'').normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').toLowerCase().replace(/\\s+/g,' ').trim();
const mesIn=(id,v)=>'<input id="'+id+'" type="month" value="'+(v||'')+'">';
async function renderFixas(){const _rt=RT;
  const [{data:fe,error},{data:com,error:e2}]=await Promise.all([sb.from('v_fixed_expenses').select('*').order('valor_atual',{ascending:false}),sb.from('commitments').select('*').eq('is_active',true).order('monthly_amount',{ascending:false})]);
  if(error)throw error;if(e2)throw e2;window._com=com||[];
  const L=fe||[];window._fe=L;const hoje=mesAtual();
  const ativos=L.filter(f=>f.is_active&&(!f.end_month||f.end_month.slice(0,7)>=hoje)),inativos=L.filter(f=>!ativos.includes(f));
  const tot=ativos.reduce((s,f)=>s+Number(f.valor_atual||0),0),pago=ativos.reduce((s,f)=>s+Math.min(Number(f.pago_mes||0),Number(f.valor_atual||0)),0);
  const conta=ativos.filter(f=>f.channel==='conta').reduce((s,f)=>s+Number(f.valor_atual||0),0);
  const grupos={};ativos.forEach(f=>{(grupos[f.group_name||'Outros']=grupos[f.group_name||'Outros']||[]).push(f)});
  const linha=(f)=>{const i=L.indexOf(f);const v=Number(f.valor_atual||0),pm=Number(f.pago_mes||0),pa=Number(f.pago_mes_anterior||0);
    const dif=pa>0&&v>0&&Math.abs(pa-v)/v>0.05;const st=!ativos.includes(f)?'encerrada':pm>=v-0.5&&v>0?'<span class="pos">pago '+brl0(pm)+'</span>':pm>0?'pago '+brl0(pm)+' de '+brl0(v):'a pagar';
    return '<div class="item" onclick="editFixa('+i+')"><div class="d"><div class="t">'+esc(f.name)+'</div><div class="s" style="white-space:normal">'+esc(f.category_name||'')+' · '+(f.channel==='cartao'?'cartão':'conta')+(f.due_day?' · dia '+f.due_day:'')+(f.end_month?' · até '+f.end_month.slice(5,7)+'/'+f.end_month.slice(0,4):'')+' · '+st+(dif?' · <span class="pill warn">último pago '+brl0(pa)+'</span>':'')+(f.proximo_valor!=null?' · <span class="pill">'+brl0(f.proximo_valor)+' a partir de '+f.proximo_desde.slice(5,7)+'/'+f.proximo_desde.slice(0,4)+'</span>':'')+(f.source==='sugerido'?' · <span class="pill">sugerido</span>':'')+'</div></div><div class="a num">'+brl0(v)+'</div></div>'};
  if(_rt!==RT)return;$('#app').innerHTML='<div class="wrap">'+voltar('Plano','#plano')+'<div class="row"><h1>Contas fixas</h1></div>'+
   '<div class="kpis"><div class="kpi"><div class="v num">'+brl0(tot)+'</div><div class="l">Total mensal</div></div><div class="kpi"><div class="v num pos">'+brl0(pago)+'</div><div class="l">Pago em '+mesNome(hoje).split(' ')[0]+'</div></div><div class="kpi"><div class="v num neg">'+brl0(tot-pago)+'</div><div class="l">A pagar no mês</div></div></div>'+
   '<p class="small muted">'+ativos.length+' contas ativas · '+brl0(conta)+' pela conta (PIX, transferência, boleto, débito) e '+brl0(tot-conta)+' no cartão. Toque numa conta para editar ou registrar um novo valor; o valor antigo fica no histórico. Estes valores entram como “comprometido” nos meses futuros do Plano.</p>'+
   '<p><button onclick="editFixa(-1)">+ Nova conta fixa</button></p>'+
   Object.entries(grupos).sort((a,b)=>b[1].reduce((s,f)=>s+Number(f.valor_atual||0),0)-a[1].reduce((s,f)=>s+Number(f.valor_atual||0),0)).map(([g,fs])=>'<h2>'+esc(g)+' · '+brl0(fs.reduce((s,f)=>s+Number(f.valor_atual||0),0))+'</h2><div class="list">'+fs.map(linha).join('')+'</div>').join('')+
   ((com||[]).length?'<h2>Financiamentos e parcelamentos</h2><p class="small muted" style="margin-top:-4px">Prazo, parcelas e saldo devedor. Toque para atualizar.</p><div class="list">'+(com||[]).map((c,i)=>{const naLista=L.some(f=>f.is_active&&(f.commitment_id===c.id||(c.kind==='financiamento'&&!!c.category_id&&f.category_id===c.category_id)));return '<div class="item" onclick="editCom('+i+')"><div class="d"><div class="t">'+esc(c.name)+'</div><div class="s" style="white-space:normal">'+(c.end_date?'até '+fmtD(c.end_date)+'/'+c.end_date.slice(0,4):'sem prazo informado')+(c.installments_total?' · parcela '+c.installments_paid+' de '+c.installments_total:'')+(c.kind==='financiamento'?' · saldo devedor '+(c.outstanding_balance!=null?brl0(c.outstanding_balance):'<span class="pill warn">informar</span>'):'')+' · '+(naLista?'na lista acima':'<span class="pill warn">fora das contas fixas</span>')+'</div></div><div class="a num">'+brl0(c.monthly_amount)+'</div></div>'}).join('')+'</div>'+((com||[]).some(c=>!L.some(f=>f.commitment_id===c.id))?'<p class="small muted">“Fora das contas fixas” = a parcela não entra no total acima nem no comprometido do mês. Para incluir, cadastre como conta fixa.</p>':''):'')+
   (inativos.length?'<h2>Encerradas ou desativadas</h2><div class="list">'+inativos.map(linha).join('')+'</div>':'')+
   '<p class="small muted">“Sugerido” = identificado pelos pagamentos de mai–out/26; confira nome e valor. “Último pago” aparece quando o pagamento do mês anterior diferiu mais de 5% do valor cadastrado.</p></div>';
}
window.editFixa=async(i)=>{const f=i>=0?window._fe[i]:{name:'',category_id:'',channel:'conta',due_day:'',end_month:'',is_active:true,notes:'',match_pattern:''};const hoje=mesAtual();
  let hist=[];if(i>=0){const {data}=await sb.from('fixed_expense_values').select('*').eq('fixed_expense_id',f.id).order('valid_from',{ascending:false});hist=data||[];}
  const cats=S.cats.filter(c=>c.kind==='despesa').map(c=>'<option value="'+c.id+'"'+(c.id===f.category_id?' selected':'')+'>'+(c.parent_id?'  ↳ ':'')+esc(c.name)+'</option>').join('');
  openSheet('<b>'+(i>=0?esc(f.name):'Nova conta fixa')+'</b>'+(f.notes?'<p class="small muted">'+esc(f.notes)+'</p>':'')+
   (i>=0?'<div class="panel" style="margin:8px 0;padding:10px"><b class="small">Registrar novo valor</b><div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-top:6px"><input id="fv" inputmode="decimal" placeholder="valor R$">'+mesIn('fvd',hoje)+'</div><input id="fvn" placeholder="motivo (ex.: reajuste anual)" style="margin-top:6px"><p class="small muted" style="margin:6px 0 0">Vale a partir do mês escolhido; os meses anteriores mantêm o valor antigo.</p></div>'+
    '<div class="small"><b>Histórico de valores</b>'+hist.map(h=>'<div class="row" style="border-top:1px dashed var(--line);padding:4px 0"><span>desde '+h.valid_from.slice(5,7)+'/'+h.valid_from.slice(0,4)+(h.note?' · <span class="muted">'+esc(h.note)+'</span>':'')+'</span><b class="num">'+brl(h.amount)+'</b></div>').join('')+'</div>':
    '<label class="small">Valor mensal</label><input id="fv" inputmode="decimal"><label class="small">A partir de</label>'+mesIn('fvd',hoje))+
   '<label class="small">Nome</label><input id="fn" value="'+esc(f.name)+'"><label class="small">Categoria</label><select id="fc">'+(i<0?'<option value="">escolha…</option>':'')+cats+'</select>'+
   '<div style="display:grid;grid-template-columns:1fr 1fr;gap:6px"><div><label class="small">Pago por</label><select id="fch"><option value="conta"'+(f.channel==='conta'?' selected':'')+'>Conta</option><option value="cartao"'+(f.channel==='cartao'?' selected':'')+'>Cartão</option></select></div><div><label class="small">Dia de vencimento</label><input id="fd" inputmode="numeric" value="'+(f.due_day||'')+'"></div></div>'+
   '<label class="small">Termina em (vazio = sem prazo)</label>'+mesIn('fe',f.end_month?f.end_month.slice(0,7):'')+
   (i<0||!f.payee_key?'<label class="small">Texto para reconhecer o pagamento no extrato (opcional)</label><input id="fm" value="'+esc(f.match_pattern||'')+'" placeholder="ex.: nome do recebedor">':'')+
   '<label class="chk" style="margin:10px 0"><input type="checkbox" id="fa"'+(f.is_active?' checked':'')+'> Ativa</label>'+
   '<div class="row"><button class="ghost" onclick="closeSheet()">Cancelar</button><button onclick="saveFixa('+i+')">Salvar</button></div>')};
window.saveFixa=async(i)=>{const now=new Date().toISOString();const f=i>=0?window._fe[i]:null;
  const row={name:$('#fn').value.trim(),category_id:$('#fc').value,channel:$('#fch').value,due_day:Math.round(num($('#fd').value)||0)||null,end_month:$('#fe').value?$('#fe').value+'-01':null,is_active:$('#fa').checked,updated_at:now,updated_by:S.member?.id};
  if($('#fm'))row.match_pattern=normTxt($('#fm').value)||null;
  if(!row.name||!row.category_id){toast('Informe nome e categoria');return;}
  if(row.due_day&&(row.due_day<1||row.due_day>31)){toast('Dia de vencimento inválido');return;}
  const v=num($('#fv').value),vd=$('#fvd').value;
  if(i<0&&(v==null||v<0||!vd)){toast('Informe o valor e o mês de início');return;}
  if(v!=null&&(v<0||!vd)){toast('Valor ou mês inválido');return;}
  let id=f?.id;
  if(f){const {error}=await sb.from('fixed_expenses').update(row).eq('id',id);if(error){toast('Não salvou: '+error.message);return;}}
  else{row.start_month=vd+'-01';row.source='hugo';const {data,error}=await sb.from('fixed_expenses').insert(row).select('id').single();if(error){toast('Não salvou: '+error.message);return;}id=data.id;}
  if(v!=null){const {error}=await sb.from('fixed_expense_values').upsert({fixed_expense_id:id,valid_from:vd+'-01',amount:v,note:($('#fvn')?.value||'').trim()||(f?'alterado no app':'cadastro'),created_by:S.member?.id},{onConflict:'fixed_expense_id,valid_from'});if(error){toast('Valor não salvou: '+error.message);return;}}
  closeSheet();toast(v!=null&&f?'Novo valor registrado':'Conta fixa salva');route()};

// ---------- Revisão ----------
const normK=(x)=>String(x||'').normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').toLowerCase().replace(/\\s+/g,' ').trim();
async function renderRevisao(){const _rt=RT;
  const {data:rows,error}=await sb.from('v_tx').select('*').eq('review_status','pending').order('event_date',{ascending:false}).limit(1000);if(error)throw error;
  const R=rows||[];const tot=R.reduce((s,r)=>s+Math.abs(Number(r.amount)),0);
  const M={};R.forEach(r=>{const k=normK(r.counterpart_name||r.description);(M[k]=M[k]||{k,name:r.counterpart_name||r.description,rows:[],s:0}).rows.push(r);M[k].s+=Number(r.amount)});
  const G=Object.values(M).sort((a,b)=>b.rows.length-a.rows.length||Math.abs(b.s)-Math.abs(a.s));
  if(_rt!==RT)return;window._rows=R;window._grp=G;
  const opt=(sel)=>S.cats.map(c=>'<option value="'+c.id+'"'+(c.id===sel?' selected':'')+'>'+(c.parent_id?'  ↳ ':'')+esc(c.name)+'</option>').join('');
  $('#app').innerHTML='<div class="wrap"><h1>Revisão</h1><p class="small muted">'+(R.length?R.length+(R.length===1?' lançamento':' lançamentos')+' sem categoria ('+brl(tot)+') em '+G.length+(G.length===1?' estabelecimento':' estabelecimentos')+'. Escolha a categoria uma vez para o grupo; com “criar regra”, os próximos lançamentos iguais já entram classificados.':'')+'</p>'+
   (G.length?G.map((g,i)=>{const cs=[...new Set(g.rows.map(r=>r.category_id))];const sug=cs.length===1&&cs[0]?cs[0]:'';const n=g.rows.length;const ds=g.rows.map(r=>r.event_date).sort();
     return '<div class="panel grp" id="g'+i+'"><div class="row"><b>'+esc(g.name)+'</b><span class="num '+(g.s<0?'':'pos')+'">'+brl(g.s)+'</span></div>'+
      '<div class="small muted">'+n+(n===1?' lançamento · '+fmtD(ds[0]):' lançamentos · '+fmtD(ds[0])+' a '+fmtD(ds[n-1]))+(sug?' · sugestão: '+esc((S.cats.find(c=>c.id===sug)||{}).name||''):'')+'</div>'+
      '<select id="gc'+i+'" aria-label="Categoria para '+esc(g.name)+'"><option value="">Escolha a categoria…</option>'+opt(sug)+'</select>'+
      '<label class="chk"><input type="checkbox" id="gr'+i+'" checked> Criar regra para os próximos de “'+esc(g.name)+'”</label>'+
      '<div class="row" style="margin-top:10px"><span></span><button id="gb'+i+'" onclick="lotClass('+i+')">'+(n===1?'Classificar':'Classificar os '+n)+'</button></div>'+
      '<details><summary>'+(n===1?'Ver o lançamento':'Ver os '+n+' lançamentos (classificar um a um)')+'</summary><div class="list">'+g.rows.map(txRow).join('')+'</div></details></div>'}).join(''):'<div class="list"><div class="item">Fila vazia. Tudo classificado.</div></div>')+'</div>';
}
window.lotClass=async(i)=>{const g=(window._grp||[])[i];if(!g)return;const cat=$('#gc'+i).value;if(!cat){toast('Escolha a categoria do grupo');$('#gc'+i).focus();return}
  const rule=$('#gr'+i).checked,b=$('#gb'+i);if(b.disabled)return;b.disabled=true;b.textContent='Classificando…';
  let ok=0,err=null;for(let k=0;k<g.rows.length;k++){const {error}=await sb.rpc('set_transaction_category',{p_tx:g.rows[k].id,p_category:cat,p_create_rule:rule&&k===0});if(error){err=error;break}ok++}
  const cn=(S.cats.find(c=>c.id===cat)||{}).name||'';
  if(err)toast(ok+' de '+g.rows.length+' classificados. Erro: '+err.message);else toast((ok===1?'1 lançamento':ok+' lançamentos')+' em '+cn+(rule?' · regra criada':''));route()};

// ---------- Mais (conexão, sincronizações, membros, duplicidades, aparência, documentos) ----------
const haQuanto=(iso)=>{if(!iso)return '—';const min=Math.round((Date.now()-new Date(iso).getTime())/60000);if(min<2)return 'agora';if(min<60)return 'há '+min+' min';const h=Math.round(min/60);if(h<48)return 'há '+h+(h===1?' hora':' horas');return 'há '+Math.round(h/24)+' dias'};
const dataHora=(iso)=>iso?new Date(iso).toLocaleString('pt-BR',{timeZone:TZ,day:'2-digit',month:'2-digit',year:'numeric',hour:'2-digit',minute:'2-digit'}):'—';
const CONEXAO={UPDATED:['atualizada',''],UPDATING:['atualizando',''],OUTDATED:['desatualizada','warn'],LOGIN_ERROR:['precisa reconectar','bad'],WAITING_USER_INPUT:['aguardando você','warn'],DELETED_AT_PROVIDER:['removida','bad']};
const SYNC={SUCCESS:['sem erros',''],PARTIAL:['parcial','warn'],ERROR:['com erro','bad'],FAILED:['com erro','bad'],RUNNING:['em andamento','']};
const PAPEL={owner:'dono',admin:'administrador',member:'membro',viewer:'leitura'};
const ORIGEM={cron:'automática',manual:'manual',webhook:'aviso do banco'};
async function renderOperacao(q){const _rt=RT;
  const [r1,r2,r3,r4,r5]=await Promise.all([sb.from('v_sync_status').select('*'),sb.from('sync_jobs').select('*').order('started_at',{ascending:false}).limit(8),sb.from('project_docs').select('name,updated_at').order('name'),sb.from('household_members').select('id,display_name,role,email,auth_user_id'),sb.from('data_quality_issues').select('*').eq('kind','duplicate_suspect').eq('status','open').order('created_at',{ascending:false}).limit(50)]);
  for(const r of [r1,r2,r3,r4,r5])if(r.error)throw r.error;
  const sync=r1.data,jobs=r2.data,docs=r3.data,members=r4.data,dups=r5.data||[];
  const st=(sync||[])[0]||{};const cx=CONEXAO[st.status]||[st.status?String(st.status).toLowerCase():'sem conexão','bad'];const tema=temaAtual();
  if(_rt!==RT)return;$('#app').innerHTML='<div class="wrap"><h1>Mais</h1>'+
   '<div class="panel"><div class="row"><b>Conexão com o banco'+(st.connector_name?' · '+esc(st.connector_name):'')+'</b><span class="pill'+(cx[1]?' '+cx[1]:'')+'">'+esc(cx[0])+'</span></div>'+
   '<p class="small muted">Dados do banco atualizados '+haQuanto(st.provider_updated_at)+' ('+dataHora(st.provider_updated_at)+')<br>Última sincronização sem erros: '+haQuanto(st.last_ok_sync)+'<br>Autorização do app vale até '+(st.consent_expires_at?new Date(st.consent_expires_at).toLocaleDateString('pt-BR',{timeZone:TZ}):'—')+(st.consent_warning?' <span class="pill warn">renovar</span>':'')+'<br>Erros nos últimos 7 dias: '+(st.errors_7d??0)+'</p></div>'+
   '<h2 id="dup">Possíveis duplicidades</h2>'+(dups.length?'<div class="list">'+dups.map(d=>{const x=d.detail||{};return '<div class="item"><div class="d"><div class="t">'+esc(x.description||x.descricao||'Lançamento '+String(d.transaction_id||'').slice(0,8))+'</div><div class="s">'+(x.event_date?fmtD(x.event_date)+' · ':'')+'aberta '+haQuanto(d.created_at)+'</div></div><div class="a num">'+(x.amount!=null?brl(x.amount):'')+'</div></div>'}).join('')+'</div><p class="small muted">Lançamentos que parecem repetidos ficam fora das somas até serem conferidos.</p>':'<div class="panel small muted">Nenhuma duplicidade em aberto. O sistema confere a cada sincronização.</div>')+
   '<h2>Sincronizações</h2><div class="list">'+(jobs||[]).map(j=>{const sj=SYNC[j.status]||[String(j.status||'').toLowerCase(),'warn'];return '<div class="item"><div class="d"><div class="t">'+dataHora(j.started_at)+' · '+esc(ORIGEM[j.trigger]||j.trigger||'')+'</div><div class="s">'+j.tx_fetched+' lidos, '+j.tx_new+' novos, '+j.tx_updated+' alterados</div></div><span class="pill'+(sj[1]?' '+sj[1]:'')+'">'+esc(sj[0])+'</span></div>'}).join('')+'</div>'+
   '<h2>Membros</h2><div class="list">'+(members||[]).map(m=>'<div class="item"'+(['owner','admin'].includes(S.member?.role)&&m.id!==S.member?.id?' onclick="gerarAcesso(\\''+m.id+'\\',\\''+esc(m.display_name)+'\\')"':'')+'><div class="d"><div class="t">'+esc(m.display_name)+' <span class="muted" style="font-weight:400">('+esc(PAPEL[m.role]||m.role)+')</span></div><div class="s">'+(m.email?esc(m.email):'sem e-mail')+'</div></div><span class="pill'+(m.auth_user_id?'':' warn')+'">'+(m.auth_user_id?'com login':'sem login')+'</span></div>').join('')+'</div>'+(['owner','admin'].includes(S.member?.role)?'<p class="small muted">Toque num membro para gerar um link de primeiro acesso ou de troca de senha (vale 1 hora, uso único).</p>':'')+
   '<h2>Aparência</h2><div class="panel"><div class="seg" id="tema" role="group" aria-label="Tema">'+[['auto','Automático'],['claro','Claro'],['escuro','Escuro']].map(([k,l])=>'<button type="button" data-t="'+k+'" class="'+(tema===k?'on':'')+'" aria-pressed="'+(tema===k)+'" onclick="setTema(&quot;'+k+'&quot;)">'+l+'</button>').join('')+'</div><p class="small muted" style="margin:6px 0 0">Automático segue o celular ou o computador. A escolha fica guardada neste aparelho.</p></div>'+
   '<h2>Cadastros</h2><div class="list"><a class="item" href="#fixas" style="text-decoration:none;color:inherit"><div class="d"><div class="t">Contas fixas</div><div class="s">valores, financiamentos e histórico de reajustes</div></div><span class="muted">›</span></a></div>'+
   '<h2>Documentação do projeto</h2><div class="list">'+((docs||[]).map(d=>'<div class="item" onclick="openDoc(\\''+esc(d.name)+'\\')"><div class="d"><div class="t">'+esc(d.name)+'</div><div class="s">atualizado '+new Date(d.updated_at).toLocaleDateString('pt-BR',{timeZone:TZ})+'</div></div><span class="muted">›</span></div>').join('')||'<div class="item">Nenhum documento ainda.</div>')+'</div>'+
   '<p class="small muted">App v${APP_VERSION} · '+esc(S.member?.display_name||'')+' · <a href="#" id="out">sair</a></p></div>';
  $('#out').onclick=(e)=>{e.preventDefault();sb.auth.signOut().then(()=>location.reload())};
  if(q&&q.get('sec')==='dup')requestAnimationFrame(()=>{const e=$('#dup');if(e)e.scrollIntoView()});
}
window.gerarAcesso=async(id,nome)=>{openSheet('<b>Acesso de '+esc(nome)+'</b><p class="small muted">Gerando link…</p>');const {data,error}=await sb.functions.invoke('member-invite',{body:{member_id:id}});
  if(error||!data?.url){openSheet('<b>Acesso de '+esc(nome)+'</b><p class="small">Não foi possível gerar o link: '+esc(error?.message||data?.error||'erro')+'</p><button class="ghost" onclick="closeSheet()">Fechar</button>');return;}
  window._link=data.url;openSheet('<b>Link de acesso de '+esc(nome)+'</b><p class="small muted">Envie para '+esc(nome)+' (WhatsApp, por exemplo). Vale '+esc(data.validade)+'. Ao abrir, ela cria a própria senha.</p><textarea readonly style="width:100%;height:90px;font-size:12px">'+esc(data.url)+'</textarea><div class="row" style="margin-top:10px"><button class="ghost" onclick="navigator.clipboard.writeText(window._link).then(()=>toast(\\'Link copiado\\'))">Copiar</button>'+(navigator.share?'<button onclick="navigator.share({title:\\'Acesso ao app de finanças\\',url:window._link})">Compartilhar</button>':'')+'</div>');};
window.openDoc=async(name)=>{const {data}=await sb.from('project_docs').select('content').eq('name',name).single();openSheet('<b>'+esc(name)+'</b><pre>'+esc(data?.content||'')+'</pre><button class="ghost" onclick="closeSheet()">Fechar</button>')}

// ---------- layout de notebook: seções em duas colunas ----------
const WIDE=matchMedia('(min-width:1000px)');const DESK=['inicio','plano','cartao','fixas','operacao','simular','orcamento','meta'];
function desk(){const w=$('#app>.wrap');if(!w||w.dataset.desk||!WIDE.matches||!DESK.includes(S.view))return;w.dataset.desk='1';
  const kids=[...w.children];const i0=kids.findIndex(k=>k.tagName==='H2');if(i0<0)return;
  const box=document.createElement('div');box.className='secs';let sec=null;
  kids.slice(i0).forEach(k=>{if(k.tagName==='H2'||!sec){sec=document.createElement('div');sec.className='sec';box.appendChild(sec)}sec.appendChild(k)});
  w.appendChild(box)}
new MutationObserver(desk).observe($('#app'),{childList:true});
WIDE.addEventListener('change',()=>{if(S.user)route()});

// ---------- acessibilidade: itens com onclick viram botões de teclado ----------
function a11y(root){root.querySelectorAll('[onclick]:not(button):not(a):not(input):not(select):not(label):not(summary):not(#sheet)').forEach(e=>{if(!e.hasAttribute('tabindex')){e.setAttribute('tabindex','0');e.setAttribute('role','button')}})}
new MutationObserver(()=>a11y($('#app'))).observe($('#app'),{childList:true,subtree:true});new MutationObserver(()=>a11y($('#sheetBody'))).observe($('#sheetBody'),{childList:true,subtree:true});
document.addEventListener('keydown',(e)=>{const t=e.target;if((e.key==='Enter'||e.key===' ')&&t&&t.getAttribute&&t.getAttribute('role')==='button'&&t.tagName!=='BUTTON'){e.preventDefault();t.click()}});
document.querySelectorAll('.tabs a span').forEach(x=>x.setAttribute('aria-hidden','true'));document.getElementById('tabs').setAttribute('aria-label','Menu');
// ---------- tema escolhido no app (automático / claro / escuro) ----------
const TEMA_COR={claro:'#0F6E6E',escuro:'#131C19'};
function aplicaTema(t){const r=document.documentElement;if(t==='claro')r.setAttribute('data-theme','light');else if(t==='escuro')r.setAttribute('data-theme','dark');else r.removeAttribute('data-theme');
  const m=document.querySelector('meta[name=theme-color]');if(m)m.setAttribute('content',t==='escuro'||(t!=='claro'&&matchMedia('(prefers-color-scheme: dark)').matches)?TEMA_COR.escuro:TEMA_COR.claro)}
const temaAtual=()=>{try{return localStorage.getItem('ff-tema')||'auto'}catch(e){return 'auto'}};
window.setTema=(t)=>{try{localStorage.setItem('ff-tema',t)}catch(e){}aplicaTema(t);document.querySelectorAll('#tema button').forEach(b=>{b.classList.toggle('on',b.dataset.t===t);b.setAttribute('aria-pressed',b.dataset.t===t?'true':'false')})};
aplicaTema(temaAtual());

boot();
</script>
</body></html>`;

const CSP = "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; connect-src 'self' " + SUPABASE_URL + " wss://hrsinekxrfiphlhpoewp.supabase.co; img-src 'self' data:; manifest-src 'self'; frame-ancestors 'none'";
Bun.serve({
  port: Number(Bun.env.PORT || 3000),
  fetch(req) {
    const p = new URL(req.url).pathname;
    if (p === "/manifest.json") return new Response(MANIFEST, { headers: { "Content-Type": "application/manifest+json", "Cache-Control": "public, max-age=3600" } });
    if (p === "/icon.png") return new Response(ICON, { headers: { "Content-Type": "image/png", "Cache-Control": "public, max-age=86400" } });
    if (p === "/sw.js") return new Response(SW, { headers: { "Content-Type": "application/javascript", "Service-Worker-Allowed": "/" } });
    if (p === "/health") return new Response(JSON.stringify({ ok: true, version: APP_VERSION }), { headers: { "Content-Type": "application/json" } });
    if (p !== "/") return Response.redirect(new URL(req.url).origin + "/", 302);
    return new Response(HTML, { headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-cache", "X-Content-Type-Options": "nosniff", "Referrer-Policy": "no-referrer", "Strict-Transport-Security": "max-age=31536000", "Content-Security-Policy": CSP } });
  },
});
