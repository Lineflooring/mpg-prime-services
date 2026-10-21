# MPG Prime Services — sitio web

Empresa operativa en España de **MPG Prime Group**. Sitio estático trilíngue
(ES por defecto / EN / PT, selector de banderas en todas las páginas),
identidad visual del grupo (carbón #0A0D12, dorado #C4A35A, crema #F7F4EF,
sello oficial MPG, Fraunces + Montserrat).

## Páginas
- `index.html` — home: hero, respaldo del grupo (500+ proyectos, 4,8 Google,
  1 año de garantía, desde 2018 — siempre atribuido a la división de
  construcción en **Florida, EE. UU.**), servicios, proceso, galería Florida.
- `servicios.html` — orden de servicios fijado por el dueño (2026-10-21):
  reforma integral (destacada), cerámica y porcelanato, laminado, SPC,
  baños, cocinas, pintura (solo pintar / completa) y extras (retirada,
  nivelación, rodapié). **Sin precios visibles.** Posicionamiento: MPG
  Prime Services como gestor de proyecto con red de subcontratistas
  verificada. La misma orden se refleja en las tarjetas de la home, en el
  pie de todas las páginas y en los chips del paso 1 de `presupuesto.html`.
- `presupuesto.html` — formulario de solicitud de presupuesto en 6 pasos
  (servicios, dirección, mano de obra/materiales, plazo, datos, visita
  gratuita), modelo del formulario de propuestas de Line Flooring adaptado
  a España. Sin calculadora ni totales instantáneos.
- `subcontratistas.html` — bloque introductorio de selección (red limitada
  por zona, lista de 16 oficios) + Paso 0 (filtro Sí/No eliminatorio: RC,
  empresa activa, REA, PRL, SS/Hacienda; un "No" bloquea y el intento se
  registra) + registro completo con oficios en selección múltiple y 6
  documentos, cada uno con fecha de vencimiento obligatoria. Estado
  inicial: **PENDIENTE**.
- `inversores.html` — propuesta B2B + formulario propio.
- `contacto.html` — WhatsApp +1 (407) 443-4160, info@mpgprimeservices.es, formulario.

## Cómo se capturan los datos
**Fuente única de verdad: Supabase** (proyecto del grupo `pwqrkiskvkjeujidyyem`).
El sitio vive en GitHub Pages: **Netlify Forms no existe ahí** (las antiguas
llamadas quedaron como no-ops retirados en `assets/app.js`).

- Formularios → tabla `mpg_services_leads` (tipos: presupuesto, contacto,
  inversor). El formulario solo muestra confirmación si el insert se guardó;
  si falla, muestra error (nada de éxitos falsos).
- Registro de subcontratista → tabla `mpg_services_subs` + los 6 documentos
  subidos al **bucket privado `sub-docs`** (rutas y vencimientos en la fila).
- Intentos bloqueados en el Paso 0 → `mpg_services_sub_attempts`.

**Activación (único paso pendiente):** ejecutar `supabase/schema.sql` en el
SQL Editor de Supabase, sustituyendo antes `PON-AQUI-TU-CLAVE` por la clave
del panel. Crea tablas, bucket, RLS (anon solo inserta) y las funciones RPC
del panel. Hasta ejecutarlo, los formularios muestran error al enviar.

## Panel interno
`panel.html` (no enlazado desde el sitio, `noindex`): clave de acceso en
localStorage, patrón de la Tabela de Schedule (RPC con `p_key`). Lista leads
con estado editable, subcontratistas con **semáforo calculado** desde los 6
vencimientos (🔴 vencido/en falta · 🟡 ≤30 días o pendiente de revisión ·
🟢 vigente y aprobado), botón de aprobación y descarga de documentos con la
cabecera `x-panel-key`.

## Motor de vencimientos
Script diario fuera del repo: `~/workspace/spain/mpg-services-tools/`
(`expiry_check.py` + cron diario 08:09 Europe/Madrid). Nace en **modo
report** (sin emails) hasta que exista la casilla info@mpgprimeservices.es;
el informe diario queda en `reports/`. Interruptor de envío en su `.env`.

## Pendiente
1. Ejecutar el schema en Supabase (paso del propietario, ver arriba).
2. Casilla info@mpgprimeservices.es (clic de contraseña en GoDaddy) → tras
   eso, SPF/DKIM y activar `MPG_MAIL_MODE=send` en el motor.
3. Dominio propio: CNAME `mpgprimeservices.es` + DNS en GoDaddy (A de Pages
   en el apex + CNAME www → lineflooring.github.io, sin tocar el TXT _dmarc).
   Hacerlo junto: el CNAME sin DNS dejaría el sitio inaccesible.
4. Páginas por ciudad (Alicante, Valencia, Málaga, Madrid) y ciudad+servicio.
