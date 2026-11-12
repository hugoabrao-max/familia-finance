// Família Finance AI — app (v0.1) servido por Edge Function
// Rotas: /  (SPA)  /manifest.json  /sw.js  /health
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const SUPABASE_URL = "https://hrsinekxrfiphlhpoewp.supabase.co";
const ANON_KEY = "sb_publishable_MzeZ3Hg-lJRA6O_PZZiAIA_Y3dMoC4g";
const APP_VERSION = "0.1.0";

const MANIFEST = JSON.stringify({
  name: "Família Finance AI", short_name: "Finanças", start_url: "/functions/v1/app/", scope: "/functions/v1/app/",
  display: "standalone", background_color: "#F5F7F5", theme_color: "#0F6E6E", lang: "pt-BR",
  icons: [{ src: "data:image/svg+xml;utf8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" rx="14" fill="#0F6E6E"/><path d="M14 44 L26 30 L34 36 L50 18" stroke="#fff" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>'), sizes: "any", type: "image/svg+xml" }],
});

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
<link rel="manifest" href="manifest.json">
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
:root{--bg:#F5F7F5;--panel:#FFFFFF;--ink:#17241F;--ink2:#5B6B64;--line:#DCE3DF;--acc:#0F6E6E;--acc2:#E3F0EE;--pos:#237A48;--neg:#B5432D;--warn:#9A6B00;--tab:#FFFFFF;
 box-sizing:border-box;padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}
@media (prefers-color-scheme: dark){:root:not([data-theme=light]){--bg:#101715;--panel:#182220;--ink:#EEF3F0;--ink2:#9DB0A7;--line:#2A3733;--acc:#5FC2B8;--acc2:#1C3331;--pos:#6FCF8E;--neg:#F28B6F;--warn:#E3B94C;--tab:#131C19;color-scheme:dark}}
*{box-sizing:border-box}html,body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.45 "IBM Plex Sans",system-ui,sans-serif;font-feature-settings:"tnum"}
body{padding-bottom:calc(72px + env(safe-area-inset-bottom,0px))}
.wrap{max-width:720px;margin:0 auto;padding:16px}
h1{font-size:22px;font-weight:600;margin:4px 0 12px;letter-spacing:-.01em}h2{font-size:15px;font-weight:600;margin:20px 0 8px;color:var(--ink2)}
.num{font-variant-numeric:tabular-nums}.pos{color:var(--pos)}.neg{color:var(--neg)}.muted{color:var(--ink2)}.small{font-size:13px}
.panel{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:14px}
.row{display:flex;align-items:center;justify-content:space-between;gap:10px}
.kpis{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin:10px 0}.kpi{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:10px 12px}.kpi .v{font-size:19px;font-weight:600}.kpi .l{font-size:12px;color:var(--ink2)}
.hero{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:14px}.hero .big{font-size:34px;font-weight:600;letter-spacing:-.02em;line-height:1.1}
svg.chart{width:100%;height:120px;display:block;margin-top:8px}
.list{display:flex;flex-direction:column;gap:1px;background:var(--line);border:1px solid var(--line);border-radius:12px;overflow:hidden}
.item{background:var(--panel);padding:11px 14px;display:flex;justify-content:space-between;gap:10px;align-items:center;cursor:pointer}.item:active{background:var(--acc2)}
.item .d{min-width:0}.item .t{font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.item .s{font-size:12.5px;color:var(--ink2);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.item .a{font-weight:600;white-space:nowrap}
.bar{height:6px;background:var(--acc2);border-radius:3px;overflow:hidden}.bar i{display:block;height:100%;background:var(--acc)}
button,select,input{font:inherit;color:inherit}button{background:var(--acc);color:#fff;border:0;border-radius:10px;padding:11px 16px;font-weight:600;cursor:pointer}button.ghost{background:transparent;color:var(--acc);border:1px solid var(--line)}button:disabled{opacity:.5}
input,select{width:100%;background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:10px 12px}
.filters{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin:8px 0 12px}.filters .full{grid-column:1/-1}
.tabs{position:fixed;left:0;right:0;bottom:0;background:var(--tab);border-top:1px solid var(--line);display:flex;padding-bottom:env(safe-area-inset-bottom,0px);z-index:5}
.tabs a{flex:1;text-align:center;padding:10px 4px 8px;color:var(--ink2);text-decoration:none;font-size:12px;font-weight:500}.tabs a.on{color:var(--acc)}.tabs a span{display:block;font-size:20px;line-height:1.1}
.sheet{position:fixed;inset:0;background:rgba(0,0,0,.45);display:none;align-items:flex-end;z-index:10}.sheet.on{display:flex}.sheet .card{background:var(--panel);width:100%;max-width:720px;margin:0 auto;border-radius:16px 16px 0 0;padding:16px 16px calc(16px + env(safe-area-inset-bottom,0px));max-height:88vh;overflow:auto}
.pill{display:inline-block;padding:2px 8px;border-radius:999px;background:var(--acc2);color:var(--acc);font-size:12px;font-weight:500}.pill.warn{background:#FFF4D6;color:var(--warn)}.pill.bad{background:#FBE4DE;color:var(--neg)}
.toast{position:fixed;left:50%;transform:translateX(-50%);bottom:90px;background:var(--ink);color:var(--bg);padding:10px 16px;border-radius:10px;font-size:14px;display:none;z-index:20}
.login{max-width:380px;margin:12vh auto;display:flex;flex-direction:column;gap:10px}
.center{text-align:center;padding:30px 10px;color:var(--ink2)}
pre{white-space:pre-wrap;font:13px/1.5 ui-monospace,monospace;background:var(--acc2);padding:12px;border-radius:10px}
label.chk{display:flex;gap:8px;align-items:center;font-size:14px}
@media (prefers-reduced-motion: no-preference){.sheet .card{animation:up .18s ease-out}@keyframes up{from{transform:translateY(24px);opacity:.6}to{transform:none;opacity:1}}}
</style>
</head>
<body>
<div id="app"><div class="center">Carregando…</div></div>
<nav class="tabs" id="tabs" style="display:none">
 <a href="#inicio"><span>◔</span>Início</a><a href="#lancamentos"><span>≡</span>Lançamentos</a><a href="#revisao"><span>✎</span>Revisão<b id="pend"></b></a><a href="#operacao"><span>⚙</span>Operação</a>
</nav>
<div class="sheet" id="sheet" onclick="if(event.target===this)closeSheet()"><div class="card" id="sheetBody"></div></div>
<div class="toast" id="toast"></div>
<script type="module">
import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.49.1/+esm";
const sb = createClient("${SUPABASE_URL}", "${ANON_KEY}");
const $ = (s)=>document.querySelector(s);
const brl = (v)=> (v==null?'—':Number(v).toLocaleString('pt-BR',{style:'currency',currency:'BRL'}));
const brl0 = (v)=> (v==null?'—':Math.round(Number(v)).toLocaleString('pt-BR',{style:'currency',currency:'BRL',maximumFractionDigits:0}));
const esc = (s)=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const toast=(m)=>{const t=$('#toast');t.textContent=m;t.style.display='block';setTimeout(()=>t.style.display='none',2200)};
const ym=(d)=>d.toISOString().slice(0,7);
const mesNome=(m)=>{const [y,mo]=m.split('-');return new Date(Date.UTC(+y,+mo-1,1)).toLocaleDateString('pt-BR',{month:'long',year:'numeric',timeZone:'UTC'})};
const fmtD=(d)=>{const [y,m,dd]=d.split('-');return dd+'/'+m};
let S={user:null,member:null,cats:[],accounts:[],month:ym(new Date()),view:'inicio'};
window.closeSheet=()=>$('#sheet').classList.remove('on');
function openSheet(html){$('#sheetBody').innerHTML=html;$('#sheet').classList.add('on')}

// ---------- autenticação ----------
async function boot(){
  const {data:{session}} = await sb.auth.getSession();
  S.user = session?.user ?? null;
  if(!S.user){ renderLogin(); return; }
  const {data:m} = await sb.from('household_members').select('*').eq('auth_user_id',S.user.id).maybeSingle();
  S.member=m;
  if(!m){ $('#app').innerHTML='<div class="wrap"><div class="panel">Seu login existe, mas ainda não está vinculado a um membro da família. Peça ao responsável para cadastrar o seu e-mail em Operação → Membros.</div><p><button class="ghost" id="out">Sair</button></p></div>'; $('#out').onclick=()=>sb.auth.signOut().then(()=>location.reload()); return; }
  const [{data:cats},{data:accs}] = await Promise.all([sb.from('categories').select('*').order('sort'), sb.from('accounts').select('id,name,subtype,number,balance,credit_limit,available_credit_limit')]);
  S.cats=cats||[]; S.accounts=accs||[];
  $('#tabs').style.display='flex';
  route();
  if('serviceWorker' in navigator){navigator.serviceWorker.register('sw.js').then(r=>r.active&&r.active.postMessage('cache-shell')).catch(()=>{});}
}
function renderLogin(){
  $('#app').innerHTML='<div class="wrap"><form class="login" id="lf"><h1>Família Finance AI</h1><p class="muted small">Entre com o e-mail e a senha cadastrados.</p><input id="em" type="email" placeholder="e-mail" autocomplete="username" required><input id="pw" type="password" placeholder="senha" autocomplete="current-password" required><button>Entrar</button><p class="small muted" id="err"></p></form></div>';
  $('#lf').onsubmit=async(e)=>{e.preventDefault();const {error}=await sb.auth.signInWithPassword({email:$('#em').value.trim(),password:$('#pw').value});if(error){$('#err').textContent='Não foi possível entrar: '+error.message;return;}location.reload();};
}

// ---------- roteamento ----------
window.addEventListener('hashchange',route);
function route(){
  const h=(location.hash||'#inicio').slice(1).split('?');S.view=h[0];
  document.querySelectorAll('.tabs a').forEach(a=>a.classList.toggle('on',a.getAttribute('href')==='#'+S.view));
  const q=new URLSearchParams(h[1]||'');
  ({inicio:renderInicio,lancamentos:()=>renderLancamentos(q),revisao:renderRevisao,operacao:renderOperacao}[S.view]||renderInicio)();
  refreshPending();
}
async function refreshPending(){const {count}=await sb.from('transactions').select('id',{count:'exact',head:true}).eq('review_status','pending');$('#pend').textContent=count?' '+count:'';}
function monthPicker(){const opts=[];const d=new Date();for(let i=0;i<14;i++){const m=ym(new Date(Date.UTC(d.getUTCFullYear(),d.getUTCMonth()-i,1)));opts.push('<option value="'+m+'"'+(m===S.month?' selected':'')+'>'+mesNome(m)+'</option>')}return '<select id="mp">'+opts.join('')+'</select>';}
function bindMonth(cb){$('#mp').onchange=(e)=>{S.month=e.target.value;cb();}}

// ---------- Início ----------
async function renderInicio(){
  const m=S.month, prev=ym(new Date(Date.UTC(+m.slice(0,4),+m.slice(5,7)-2,1)));
  const [{data:sum},{data:cat},{data:daily},{data:dailyPrev},{data:sync}] = await Promise.all([
    sb.from('v_month_summary').select('*').in('month',[m+'-01',prev+'-01']),
    sb.from('v_category_month').select('*').eq('month',m+'-01').eq('category_kind','despesa'),
    sb.from('v_daily_flow').select('*').gte('event_date',m+'-01').lt('event_date',nextMonth(m)+'-01'),
    sb.from('v_daily_flow').select('*').gte('event_date',prev+'-01').lt('event_date',m+'-01'),
    sb.from('v_sync_status').select('*')]);
  const cur=(sum||[]).find(r=>r.month===m+'-01')||{}, pv=(sum||[]).find(r=>r.month===prev+'-01')||{};
  const groups={};(cat||[]).forEach(r=>{const g=groups[r.group_id]||(groups[r.group_id]={name:r.group_name,total:0,n:0,id:r.group_id});g.total+=Number(r.total);g.n+=Number(r.n)});
  const gl=Object.values(groups).sort((a,b)=>a.total-b.total);const maxg=Math.abs(gl[0]?.total||1);
  const cum=cumulative(daily||[],m), cumPrev=cumulative(dailyPrev||[],prev);
  const today=new Date().toISOString().slice(0,10);const isCur=m===ym(new Date());
  const dayN=isCur?+today.slice(8,10):cum.length;
  const spentToDate=cum[Math.min(dayN,cum.length)-1]||0, prevSameDay=cumPrev[Math.min(dayN,cumPrev.length)-1]||0;
  const st=(sync||[])[0];
  $('#app').innerHTML='<div class="wrap">'+
   '<div class="row"><h1>Início</h1>'+monthPicker()+'</div>'+
   '<div class="hero"><div class="small muted">Gasto acumulado'+(isCur?' até hoje (dia '+dayN+')':' no mês')+'</div><div class="big num neg">'+brl0(-spentToDate)+'</div>'+
   '<div class="small muted">Mesmo dia do mês anterior: <b class="num">'+brl0(-prevSameDay)+'</b> '+delta(spentToDate,prevSameDay)+'</div>'+
   chart(cum,cumPrev,dayN)+'</div>'+
   '<div class="kpis"><div class="kpi"><div class="v num pos">'+brl0(cur.receitas)+'</div><div class="l">Receitas</div></div><div class="kpi"><div class="v num neg">'+brl0(cur.despesas)+'</div><div class="l">Despesas</div></div><div class="kpi"><div class="v num '+(Number(cur.resultado)>=0?'pos':'neg')+'">'+brl0(cur.resultado)+'</div><div class="l">Resultado</div></div></div>'+
   (cur.pendentes?'<a href="#revisao" style="text-decoration:none"><div class="panel row"><span>'+cur.pendentes+' lançamentos sem categoria</span><span class="pill warn">'+brl0(cur.valor_pendente)+'</span></div></a>':'')+
   '<h2>Despesas por categoria</h2><div class="list">'+(gl.length?gl.map(g=>'<a class="item" href="#lancamentos?month='+m+'&group='+g.id+'" style="text-decoration:none;color:inherit"><div class="d" style="flex:1"><div class="t">'+esc(g.name)+'</div><div class="bar"><i style="width:'+Math.round(Math.abs(g.total)/maxg*100)+'%"></i></div></div><div class="a num">'+brl0(g.total)+'</div></a>').join(''):'<div class="item">Sem despesas no período.</div>')+'</div>'+
   '<h2>Contas</h2><div class="list">'+S.accounts.map(a=>'<div class="item"><div class="d"><div class="t">'+esc(a.name)+'</div><div class="s">'+esc(a.subtype==='CREDIT_CARD'?'Cartão final '+a.number:a.subtype==='SAVINGS_ACCOUNT'?'Poupança':'Conta corrente')+'</div></div><div class="a num">'+brl(a.balance)+'</div></div>').join('')+'</div>'+
   '<p class="small muted">'+(st?('Dados do banco atualizados em '+new Date(st.provider_updated_at).toLocaleString('pt-BR')+(st.consent_warning?' · <span class="pill warn">consentimento vence em breve</span>':'')+(st.last_job_status==='FAILED'?' · <span class="pill bad">última sincronização falhou</span>':'')):'Sem conexão bancária registrada.')+'</p>'+
  '</div>';
  bindMonth(renderInicio);
}
function nextMonth(m){return ym(new Date(Date.UTC(+m.slice(0,4),+m.slice(5,7),1)))}
function cumulative(rows,m){const days=new Date(Date.UTC(+m.slice(0,4),+m.slice(5,7),0)).getUTCDate();const by={};rows.forEach(r=>{by[r.event_date]=(by[r.event_date]||0)+Number(r.saidas||0)});const out=[];let acc=0;for(let d=1;d<=days;d++){acc+=by[m+'-'+String(d).padStart(2,'0')]||0;out.push(acc)}return out}
function delta(a,b){if(!b)return'';const p=Math.round((Math.abs(a)/Math.abs(b)-1)*100);return'<span class="'+(p>0?'neg':'pos')+'">('+(p>0?'+':'')+p+'%)</span>'}
function chart(cur,prev,dayN){const W=600,H=120,P=6;const max=Math.max(Math.abs(Math.min(...cur,0)),Math.abs(Math.min(...prev,0)),1);const n=Math.max(cur.length,prev.length);const x=i=>P+(W-2*P)*i/(n-1), y=v=>H-P-(H-2*P)*Math.abs(v)/max;
  const path=(arr,upto)=>arr.slice(0,upto).map((v,i)=>(i?'L':'M')+x(i).toFixed(1)+' '+y(v).toFixed(1)).join(' ');
  return '<svg class="chart" viewBox="0 0 '+W+' '+H+'" preserveAspectRatio="none" aria-label="Gasto acumulado por dia, mês atual e anterior"><path d="'+path(prev,prev.length)+'" fill="none" stroke="var(--line)" stroke-width="3" stroke-dasharray="4 4"/><path d="'+path(cur,dayN)+'" fill="none" stroke="var(--acc)" stroke-width="3" stroke-linejoin="round"/></svg>';}

// ---------- Lançamentos ----------
async function renderLancamentos(q){
  const month=q.get('month')||S.month; S.month=month;
  const f={group:q.get('group')||'',account:q.get('account')||'',search:q.get('search')||'',pending:q.get('pending')==='1'};
  let sel=sb.from('v_tx').select('*').eq('month',month+'-01').order('event_date',{ascending:false}).limit(400);
  if(f.group)sel=sel.eq('group_id',f.group); if(f.account)sel=sel.eq('account_id',f.account); if(f.search)sel=sel.ilike('description','%'+f.search+'%'); if(f.pending)sel=sel.eq('review_status','pending');
  const {data:rows,error}=await sel; if(error){toast(error.message)}
  const groups=S.cats.filter(c=>!c.parent_id);
  $('#app').innerHTML='<div class="wrap"><div class="row"><h1>Lançamentos</h1>'+monthPicker()+'</div>'+
   '<div class="filters"><select id="fg"><option value="">Todas as categorias</option>'+groups.map(g=>'<option value="'+g.id+'"'+(g.id===f.group?' selected':'')+'>'+esc(g.name)+'</option>').join('')+'</select>'+
   '<select id="fa"><option value="">Todas as contas</option>'+S.accounts.map(a=>'<option value="'+a.id+'"'+(a.id===f.account?' selected':'')+'>'+esc(a.subtype==='CREDIT_CARD'?'Cartão '+a.number:a.subtype==='SAVINGS_ACCOUNT'?'Poupança':'Conta corrente')+'</option>').join('')+'</select>'+
   '<input class="full" id="fs" placeholder="buscar na descrição" value="'+esc(f.search)+'"></div>'+
   '<p class="small muted">'+(rows||[]).length+' lançamentos · '+brl((rows||[]).reduce((s,r)=>s+Number(r.amount),0))+'</p>'+
   '<div class="list">'+((rows||[]).map(txRow).join('')||'<div class="item">Nada encontrado com esses filtros.</div>')+'</div></div>';
  const go=()=>{const p=new URLSearchParams({month:S.month});if($('#fg').value)p.set('group',$('#fg').value);if($('#fa').value)p.set('account',$('#fa').value);if($('#fs').value)p.set('search',$('#fs').value);location.hash='lancamentos?'+p};
  bindMonth(go);$('#fg').onchange=go;$('#fa').onchange=go;$('#fs').onchange=go;
  window._rows=rows||[];
}
function txRow(r){return '<div class="item" onclick="openTx(\\''+r.id+'\\')"><div class="d"><div class="t">'+esc(r.counterpart_name||r.description)+'</div><div class="s">'+fmtD(r.event_date)+' · '+esc(r.category_name||'sem categoria')+(r.card_last4?' · cartão '+esc(r.card_last4):'')+(r.review_status==='pending'?' · <span class="pill warn">revisar</span>':'')+'</div></div><div class="a num '+(Number(r.amount)<0?'':'pos')+'">'+brl(r.amount)+'</div></div>'}
window.openTx=(id)=>{const r=(window._rows||[]).find(x=>x.id===id);if(!r)return;
  const opts=S.cats.map(c=>'<option value="'+c.id+'"'+(c.id===r.category_id?' selected':'')+'>'+(c.parent_id?'  ↳ ':'')+esc(c.name)+'</option>').join('');
  openSheet('<div class="row"><b>'+esc(r.description)+'</b><span class="num '+(Number(r.amount)<0?'neg':'pos')+'" style="font-weight:600">'+brl(r.amount)+'</span></div>'+
   '<p class="small muted">'+fmtD(r.event_date)+'/'+r.event_date.slice(0,4)+' · '+esc(r.account_name)+(r.counterpart_name?' · '+esc(r.counterpart_name):'')+(r.installment_total?' · parcela '+r.installment_number+'/'+r.installment_total:'')+'</p>'+
   '<p class="small">Origem: '+esc(r.source==='pluggy'?'Open Finance (Santander via Pluggy)':r.source)+' · Classificação: '+esc(srcLabel(r.category_source))+(r.category_confidence?' · confiança '+Math.round(r.category_confidence*100)+'%':'')+'</p>'+
   '<select id="cx">'+opts+'</select><label class="chk" style="margin:10px 0"><input type="checkbox" id="rule" checked> Aplicar a lançamentos iguais no futuro (cria regra)</label>'+
   '<div class="row"><button class="ghost" onclick="closeSheet()">Cancelar</button><button onclick="saveTx(\\''+r.id+'\\')">Salvar categoria</button></div>');
}
function srcLabel(s){return {ajuste_usuario:'ajuste manual',pessoa:'pessoa conhecida',regra_sistema:'regra do sistema',regra_estabelecimento:'estabelecimento',padrao_operacao:'tipo de operação',pendente:'pendente'}[s]||s||'—'}
window.saveTx=async(id)=>{const cat=$('#cx').value,rule=$('#rule').checked;const {error}=await sb.rpc('set_transaction_category',{p_tx:id,p_category:cat,p_create_rule:rule});if(error){toast('Não salvou: '+error.message);return;}closeSheet();toast('Categoria salva');route();}

// ---------- Revisão ----------
async function renderRevisao(){
  const {data:rows}=await sb.from('v_tx').select('*').eq('review_status','pending').order('event_date',{ascending:false}).limit(300);
  const tot=(rows||[]).reduce((s,r)=>s+Math.abs(Number(r.amount)),0);
  $('#app').innerHTML='<div class="wrap"><h1>Revisão</h1><p class="small muted">'+(rows||[]).length+' lançamentos sem categoria, '+brl(tot)+'. Toque para classificar; marque “aplicar no futuro” para o sistema aprender.</p><div class="list">'+((rows||[]).map(txRow).join('')||'<div class="item">Fila vazia. Tudo classificado.</div>')+'</div></div>';
  window._rows=rows||[];
}

// ---------- Operação ----------
async function renderOperacao(){
  const [{data:sync},{data:jobs},{data:docs},{data:members}]=await Promise.all([sb.from('v_sync_status').select('*'),sb.from('sync_jobs').select('*').order('started_at',{ascending:false}).limit(8),sb.from('project_docs').select('name,updated_at').order('name'),sb.from('household_members').select('display_name,role,email,auth_user_id')]);
  const st=(sync||[])[0]||{};
  $('#app').innerHTML='<div class="wrap"><h1>Operação</h1>'+
   '<div class="panel"><div class="row"><b>Conexão '+esc(st.connector_name||'—')+'</b><span class="pill'+(st.status==='UPDATED'?'':' bad')+'">'+esc(st.status||'sem conexão')+'</span></div>'+
   '<p class="small muted">Última coleta do banco: '+(st.provider_updated_at?new Date(st.provider_updated_at).toLocaleString('pt-BR'):'—')+'<br>Última sincronização OK: '+(st.last_ok_sync?new Date(st.last_ok_sync).toLocaleString('pt-BR'):'—')+'<br>Autorização do app válida até: '+(st.consent_expires_at?new Date(st.consent_expires_at).toLocaleDateString('pt-BR'):'—')+(st.consent_warning?' <span class="pill warn">renovar</span>':'')+'<br>Erros nos últimos 7 dias: '+(st.errors_7d??0)+'</p></div>'+
   '<h2>Sincronizações</h2><div class="list">'+(jobs||[]).map(j=>'<div class="item"><div class="d"><div class="t">'+new Date(j.started_at).toLocaleString('pt-BR')+' · '+esc(j.trigger)+'</div><div class="s">'+j.tx_fetched+' lidos, '+j.tx_new+' novos, '+j.tx_updated+' alterados</div></div><span class="pill'+(j.status==='SUCCESS'?'':j.status==='PARTIAL'?' warn':' bad')+'">'+esc(j.status)+'</span></div>').join('')+'</div>'+
   '<h2>Membros</h2><div class="list">'+(members||[]).map(m=>'<div class="item"><div class="d"><div class="t">'+esc(m.display_name)+'</div><div class="s">'+esc(m.role)+(m.email?' · '+esc(m.email):'')+'</div></div><span class="pill'+(m.auth_user_id?'':' warn')+'">'+(m.auth_user_id?'com login':'sem login')+'</span></div>').join('')+'</div>'+
   '<h2>Documentação do projeto</h2><div class="list">'+((docs||[]).map(d=>'<div class="item" onclick="openDoc(\\''+esc(d.name)+'\\')"><div class="d"><div class="t">'+esc(d.name)+'</div><div class="s">atualizado '+new Date(d.updated_at).toLocaleDateString('pt-BR')+'</div></div><span class="muted">›</span></div>').join('')||'<div class="item">Nenhum documento ainda.</div>')+'</div>'+
   '<p class="small muted">App v${APP_VERSION} · '+esc(S.member?.display_name||'')+' · <a href="#" id="out">sair</a></p></div>';
  $('#out').onclick=(e)=>{e.preventDefault();sb.auth.signOut().then(()=>location.reload())};
}
window.openDoc=async(name)=>{const {data}=await sb.from('project_docs').select('content').eq('name',name).single();openSheet('<b>'+esc(name)+'</b><pre>'+esc(data?.content||'')+'</pre><button class="ghost" onclick="closeSheet()">Fechar</button>')}

boot();
</script>
</body></html>`;

Deno.serve((req) => {
  const p = new URL(req.url).pathname;
  if (p.endsWith("/manifest.json")) return new Response(MANIFEST, { headers: { "Content-Type": "application/manifest+json", "Cache-Control": "public, max-age=3600" } });
  if (p.endsWith("/sw.js")) return new Response(SW, { headers: { "Content-Type": "application/javascript", "Service-Worker-Allowed": "/functions/v1/app/" } });
  if (p.endsWith("/health")) return new Response(JSON.stringify({ ok: true, version: APP_VERSION }), { headers: { "Content-Type": "application/json" } });
  if (!p.endsWith("/app/")) return Response.redirect(new URL(req.url).origin + "/functions/v1/app/", 302);
  return new Response(HTML, { headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-cache", "X-Content-Type-Options": "nosniff", "Referrer-Policy": "no-referrer", "Content-Security-Policy": "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; connect-src 'self' " + SUPABASE_URL + " wss://hrsinekxrfiphlhpoewp.supabase.co; img-src 'self' data:; manifest-src 'self'" } });
});
