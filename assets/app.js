/* MPG Prime Services — motor del sitio: i18n + persistencia
   Persistencia de leads/registros:
   1) Netlify Forms (AJAX) — destino principal, visible en el panel de Netlify.
   2) Supabase (proyecto del grupo) — intento en paralelo; activo cuando se creen
      las tablas con supabase/schema.sql. Si la tabla no existe, falla en silencio. */
(function(){
  var SB_URL = 'https://pwqrkiskvkjeujidyyem.supabase.co';
  var SB_KEY = 'sb_publishable_NbgUdH8eEFszh08Epi8c0A_l8Ua80ql';
  var WA = '14074434160';
  var LOCALES = { es: 'es-ES', en: 'en-GB', pt: 'pt-PT' };

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

  function persistNetlify(formName, data){
    var body = new URLSearchParams();
    body.append('form-name', formName);
    Object.keys(data || {}).forEach(function(k){
      var v = data[k];
      body.append(k, v === undefined || v === null ? '' : (typeof v === 'object' ? JSON.stringify(v) : String(v)));
    });
    return fetch('/', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: body.toString() })
      .then(function(r){ return r.ok; }).catch(function(){ return false; });
  }
  function persistNetlifyFiles(formName, formData){
    formData.append('form-name', formName);
    return fetch('/', { method: 'POST', body: formData })
      .then(function(r){ return r.ok; }).catch(function(){ return false; });
  }
  function persistSupabase(table, row){
    return fetch(SB_URL + '/rest/v1/' + table, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'apikey': SB_KEY, 'Authorization': 'Bearer ' + SB_KEY, 'Prefer': 'return=minimal' },
      body: JSON.stringify(row)
    }).then(function(r){ return r.ok; }).catch(function(){ return false; });
  }
  function fmtEUR(n){
    return new Intl.NumberFormat(LOCALES[lang()] || 'es-ES', { style: 'currency', currency: 'EUR', maximumFractionDigits: 0 }).format(n);
  }

  window.MPS = {
    t: t, lang: lang, setLang: setLang, applyI18n: applyI18n,
    persistNetlify: persistNetlify, persistNetlifyFiles: persistNetlifyFiles,
    persistSupabase: persistSupabase, fmtEUR: fmtEUR, WA: WA
  };

  document.addEventListener('DOMContentLoaded', function(){
    document.querySelectorAll('.lang-switch button').forEach(function(b){
      b.addEventListener('click', function(){ setLang(b.dataset.lang); });
    });
    var tg = document.querySelector('.navtoggle'), mn = document.querySelector('.mobilenav');
    if (tg && mn) tg.addEventListener('click', function(){ mn.classList.toggle('open'); });
    applyI18n();
  });
})();
