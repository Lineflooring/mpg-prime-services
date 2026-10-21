# MPG Prime Services — sitio web

Empresa operativa en España de **MPG Prime Group**. Sitio estático trilíngue
(ES por defecto / EN / PT, selector de banderas en todas las páginas),
identidad visual del grupo (carbón #0A0D12, dorado #C4A35A, crema #F7F4EF,
sello oficial MPG, Fraunces + Montserrat).

## Páginas
- `index.html` — home: hero, respaldo del grupo (500+ proyectos, 4,8 Google,
  1 año de garantía, desde 2018 — siempre atribuido a la división de
  construcción en **Florida, EE. UU.**), servicios, proceso, galería Florida.
- `servicios.html` — SPC, laminado, pintura (solo pintar / completa) y extras
  (retirada, nivelación, rodapié). **Sin precios visibles.**
- `calculadora.html` — calculadora en € con la columna P2 interna
  (SPC 15,3 · laminado 12,6 · pintura 8,6 · pintura completa 18,8 €/m² ·
  rodapié 5,1 €/ml · retirada 7,0 · nivelación 10,3 €/m²). El total solo se
  revela tras nombre + WhatsApp + email (lead-gate).
- `subcontratistas.html` — Paso 0 (filtro Sí/No eliminatorio: RC, empresa
  activa, REA, PRL, SS/Hacienda; un "No" bloquea y el intento se registra) +
  registro completo con 6 documentos, cada uno con fecha de vencimiento
  obligatoria. Estado inicial: **PENDIENTE**.
- `inversores.html` — propuesta B2B + formulario propio.
- `contacto.html` — WhatsApp +1 (407) 443-4160, info@mpgprimeservices.es, formulario.

## Cómo se capturan los datos
**Destino principal: Netlify Forms** (panel de Netlify → Forms):
- `calculadora-lead` · `contacto` · `inversor`
- `subcontratista-registro` (con los 6 archivos adjuntos)
- `subcontratista-bloqueado` (intentos filtrados en el Paso 0)

**En paralelo (best effort): Supabase**, proyecto del grupo
(`pwqrkiskvkjeujidyyem`), tablas `mpg_services_leads`, `mpg_services_subs`,
`mpg_services_sub_attempts`. Para activarlo: ejecutar `supabase/schema.sql`
en el SQL Editor del proyecto. Sin las tablas, los inserts fallan en silencio
y Netlify Forms sigue siendo la fuente de verdad.

## Fase siguiente (no incluida en esta entrega)
1. Conectar dominios propios mpgprimeservices.es (principal) y .com.
2. Panel interno de subcontratistas con semáforos (verde/ámbar/rojo) estilo
   Tabla de Schedule, sobre las tablas Supabase.
3. Emails automáticos de vencimiento (30/15/7 días, día del vencimiento,
   documentos faltantes) desde info@mpgprimeservices.es (SPF/DKIM).
4. Bucket privado de Supabase Storage para los documentos de los subs.
5. Páginas por ciudad (Alicante, Valencia, Málaga, Madrid) y ciudad+servicio.
