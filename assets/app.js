/* MPG Prime Services — motor del sitio: i18n + persistencia
   Persistencia de leads/registros: SOLO Supabase (proyecto del grupo),
   fuente única de verdad. El sitio vive en GitHub Pages: Netlify Forms
   no existe ahí, así que las funciones persistNetlify* quedan como
   no-ops retirados (devuelven false sin red) para no romper llamadas
   antiguas. Las tablas y el bucket se crean con supabase/schema.sql. */
(function(){
  var SB_URL = 'https://pwqrkiskvkjeujidyyem.supabase.co';
  var SB_KEY = 'sb_publishable_NbgUdH8eEFszh08Epi8c0A_l8Ua80ql';
  var WA = '14074434160';

  function lang(){
    try { return sessionStorage.getItem('mps-lang') || 'es'; } catch(e){ return 'es'; }
  }
  function t(key){
    var l = lang();
    return (window.I18N[l] && window.I18N[l][key]) || window.I18N.es[key] || key;
  }
  function applyI18n(){
    var l = lang();
    document.documentElement.lang = l;
    document.querySelectorAll('[data-i18n]').forEach(function(el){
      var v = (window.I18N[l] && window.I18N[l][el.dataset.i18n]) || window.I18N.es[el.dataset.i18n];
      if (v !== undefined) el.innerHTML = v;
    });
    document.querySelectorAll('[data-i18n-ph]').forEach(function(el){
      var v = (window.I18N[l] && window.I18N[l][el.dataset.i18nPh]) || window.I18N.es[el.dataset.i18nPh];
      if (v !== undefined) el.setAttribute('placeholder', v);
    });
    document.querySelectorAll('.lang-switch button').forEach(function(b){
      b.classList.toggle('active', b.dataset.lang === l);
    });
    document.dispatchEvent(new CustomEvent('mps:lang', { detail: { lang: l } }));
  }
  function setLang(l){
    try { sessionStorage.setItem('mps-lang', l); } catch(e){}
    applyI18n();
  }

  /* RETIRADO: Netlify Forms no existe en GitHub Pages. No-op sin red. */
  function persistNetlify(formName, data){ return Promise.resolve(false); }
  function persistNetlifyFiles(formName, formData){ return Promise.resolve(false); }
  function persistSupabase(table, row){
    return fetch(SB_URL + '/rest/v1/' + table, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'apikey': SB_KEY, 'Authorization': 'Bearer ' + SB_KEY, 'Prefer': 'return=minimal' },
      body: JSON.stringify(row)
    }).then(function(r){ return r.ok; }).catch(function(){ return false; });
  }
  /* Sube un documento de subcontratista al bucket PRIVADO sub-docs.
     Devuelve la ruta dentro del bucket (o null si falla). */
  function uploadSubDoc(file, folder){
    if (!file) return Promise.resolve(null);
    var safe = (file.name || 'doc').replace(/[^A-Za-z0-9._-]/g, '_');
    var path = folder + '/' + Date.now() + '-' + Math.random().toString(36).slice(2, 8) + '-' + safe;
    return fetch(SB_URL + '/storage/v1/object/sub-docs/' + path, {
      method: 'POST',
      headers: { 'apikey': SB_KEY, 'Authorization': 'Bearer ' + SB_KEY, 'Content-Type': file.type || 'application/octet-stream', 'x-upsert': 'false' },
      body: file
    }).then(function(r){ return r.ok ? path : null; }).catch(function(){ return null; });
  }
  window.MPS = {
    t: t, lang: lang, setLang: setLang, applyI18n: applyI18n,
    persistNetlify: persistNetlify, persistNetlifyFiles: persistNetlifyFiles,
    persistSupabase: persistSupabase, uploadSubDoc: uploadSubDoc, WA: WA
  };

  document.addEventListener('DOMContentLoaded', function(){
    document.querySelectorAll('.lang-switch button').forEach(function(b){
      b.addEventListener('click', function(){ setLang(b.dataset.lang); });
    });
    var tg = document.querySelector('.navtoggle'), mn = document.querySelector('.mobilenav');
    if (tg && mn) tg.addEventListener('click', function(){ mn.classList.toggle('open'); });
    /* Catálogo de obras: filtro por categoría (solo existe en catalogo.html) */
    var fbar = document.querySelector('.filterbar'), fgrid = document.getElementById('cat-gallery');
    if (fbar && fgrid) {
      var fitems = Array.prototype.slice.call(fgrid.querySelectorAll('.gitem'));
      fbar.addEventListener('click', function(e){
        var b = e.target.closest('[data-filter]'); if (!b) return;
        fbar.querySelectorAll('[data-filter]').forEach(function(x){ x.classList.toggle('active', x === b); });
        var f = b.getAttribute('data-filter');
        fitems.forEach(function(it){ it.style.display = (f === 'all' || it.getAttribute('data-cat') === f) ? '' : 'none'; });
      });
    }
    applyI18n();
  });
})();
