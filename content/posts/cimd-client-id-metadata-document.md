---
title: "CIMD: adiós al infierno del Dynamic Client Registration"
slug: "cimd-client-id-metadata-document"
date: 2026-05-04T13:00:00+02:00
lastmod: 2026-05-04T13:00:00+02:00
draft: true
description: "Client ID Metadata Document: la respuesta del estándar MCP al desastre de DCR. Cómo funciona, por qué duerme tranquilo el equipo de SRE, y qué hace falta para que sea seguro."
tags:
  - "oauth2"
  - "mcp"
  - "keycloak"
  - "sre"
  - "auth"
  - "cimd"
categories:
  - "auth"
---

En [el post anterior](/posts/dcr-dynamic-client-registration/) conté cómo DCR (Dynamic Client Registration) parecía la solución perfecta para que MCP no nos pidiera registrar un cliente OAuth a mano por cada IDE del mercado, y cómo en realidad lo que conseguimos fue una base de datos de Keycloak con miles de clientes huérfanos, generados por gente que reinstalaba Cursor cada dos por tres.

El estándar de MCP miró el desastre, suspiró, y en noviembre de 2025 propuso un reemplazo que se llama **CIMD**: Client ID Metadata Document. Y la verdad es que es una de esas ideas que cuando las lees piensas "joder, claro, cómo no se nos había ocurrido antes".

## La idea, en una frase

> En vez de que el servidor genere un `client_id` para cada cliente que aparezca, el cliente **declara su identidad en una URL pública** y nos da esa URL como `client_id`.

Eso es. El resto del post es relleno.

## Cómo se ve esto en práctica

Imagina que eres VS Code. Hasta ahora, tu plugin MCP hacía un `POST` al endpoint de registro y se traía un `client_id` aleatorio. Con CIMD, lo que haces es publicar un JSON en una URL tuya, por ejemplo:

```text
https://vscode.dev/oauth/client-metadata.json
```

Y ese JSON tiene esta pinta:

```json
{
  "client_name": "Visual Studio Code",
  "client_uri": "https://code.visualstudio.com",
  "redirect_uris": [
    "vscode://vscode.mcp/oauth-callback",
    "https://vscode.dev/oauth/callback"
  ],
  "grant_types": ["authorization_code", "refresh_token"],
  "response_types": ["code"],
  "token_endpoint_auth_method": "none",
  "scope": "mcp:read mcp:write",
  "logo_uri": "https://code.visualstudio.com/assets/logo.png",
  "tos_uri": "https://code.visualstudio.com/license",
  "policy_uri": "https://code.visualstudio.com/privacy"
}
```

Cuando el plugin de VS Code inicia el flujo de autorización contra Keycloak, en vez de mandarte un `client_id` random, te manda **la URL del JSON** como `client_id`. Literalmente. El parámetro `client_id` de la petición OAuth contiene `https://vscode.dev/oauth/client-metadata.json`.

```http
GET /realms/mi-realm/protocol/openid-connect/auth
  ?client_id=https%3A%2F%2Fvscode.dev%2Foauth%2Fclient-metadata.json
  &redirect_uri=vscode%3A%2F%2Fvscode.mcp%2Foauth-callback
  &response_type=code
  &scope=mcp:read+mcp:write
  &state=...
  &code_challenge=...
  &code_challenge_method=S256
```

Keycloak ve esa URL, va a internet, **descarga el JSON**, valida que tiene lo que tiene que tener (`client_name`, `redirect_uris`, etc.) y crea un cliente **en memoria** (o en BBDD pero con TTL) usando esa URL como identificador único.

Y aquí viene lo bonito: la próxima vez que **otro usuario de VS Code en otra punta del mundo** se conecte, la URL es la misma. Keycloak ya tiene ese cliente cacheado. No crea uno nuevo. Adiós para siempre al cubo de palomitas.

## Lo bueno

**Una identidad por aplicación, no por usuario.** Esto es el cambio gordo. Antes, "VS Code" eran 17 000 clientes en BBDD. Ahora "VS Code" es 1 cliente, y es la URL que VS Code mismo declara. Si mañana sale un nuevo IDE y tiene su JSON publicado, no tienes que hacer nada para que se autentique con tu Keycloak. Cero tickets a SRE.

**El cliente es responsable de su propia identidad.** Si VS Code cambia un `redirect_uri`, edita su JSON. Keycloak descargará la nueva versión cuando expire la caché. Tú, como administrador, no te enteras. Lo cual es lo que quieres.

**Caché controlado por quien publica.** El JSON se sirve con cabeceras HTTP normales (`Cache-Control`, `ETag`, `Last-Modified`). El proveedor del cliente decide cuánto tiempo de vida tiene su descripción. Tu Keycloak respeta eso. Es la web de toda la vida funcionando sola.

**Auditable.** El `client_id` es una URL real que un humano puede abrir y ver. Si un día te encuentras un cliente sospechoso en los logs, abres la URL y juzgas. Es muchísimo mejor que un UUID `9f3a1e8c-7b22-4d11-bf66-2a4d1f0e7a98` del que solo Dios sabe a qué app pertenece.

**Limpieza automática.** Si el JSON deja de existir (404), el cliente caduca y no vuelve. Sin scripts, sin cronjobs, sin "uy, esto ya no se usa pero no me atrevo a borrarlo".

## Lo malo

No todo es color de rosa. Vamos con el lado feo.

**Acabas haciendo HTTP saliente desde Keycloak.** Tu IdP, que antes era una caja cerrada que solo recibía peticiones, ahora **sale a internet** a buscar JSONs. Esto abre la puerta a ataques **SSRF** (Server-Side Request Forgery): un atacante te manda como `client_id` algo como `http://169.254.169.254/latest/meta-data/` (la IP mágica de AWS para meterte en el servicio interno de credenciales del nodo) y, si no validas la URL, tu Keycloak se lo trae alegremente y filtra credenciales del cluster. **Estás obligado a poner una lista blanca de dominios permitidos.**

**El JSON puede mentir o cambiar.** Si VS Code publica hoy un JSON limpio y mañana lo modifica para apuntar `redirect_uri` a un dominio chungo, todos los usuarios que tengan caché viejo aún funcionan, pero los nuevos pasan por el dominio comprometido. La validación en cada descarga es **obligatoria**, no opcional.

**Dependencia de internet.** Si vscode.dev cae justo cuando tu Keycloak intenta refrescar la caché, tienes un bonito error 5xx. Hay que cachear de forma agresiva y guardar el último JSON válido como red de seguridad. Esto añade complejidad operativa que antes no existía.

**Las URIs internas del JSON también son superficie de ataque.** El JSON puede declarar un `logo_uri`, un `tos_uri`, un `policy_uri`, un `jwks_uri`... y todas esas URIs **deben validarse**. Si el JSON está alojado en `vscode.dev` (en la lista blanca) pero el logo apunta a `evil.com/te-estoy-vigilando.png`, has dejado entrar un canal lateral.

## Antes de empezar: activar la feature

Detalle importantísimo que te puede arruinar la tarde si no lo sabes: a día de hoy, **CIMD en Keycloak es una feature en preview**. Hay que activarla a mano. Por defecto viene apagada.

Tienes dos formas de hacerlo. Por flag al arrancar Keycloak:

```bash
kc.sh start --features=cimd
```

O por variable de entorno, que es lo cómodo si lo tienes en Kubernetes o en un compose:

```bash
KC_FEATURES=cimd
```

(O añadiéndolo a la lista de features que ya tengas activadas, separadas por comas.)

Si no la activas, los menús de Client Policies que voy a contar más abajo simplemente **no aparecen**. Te vas a quedar buscándolos durante un rato pensando que estás loco. Te lo aviso ahora.


## Cómo se monta esto seguro en Keycloak

En Keycloak la cosa se monta con **Client Policies**. Se configuran a nivel de **Realm**, dentro del menú **Realm Settings → Client Policies**, donde tienes dos pestañas: **Profiles** y **Policies**.

Hay dos componentes que trabajan en cadena, y nosotros los llamamos *el portero* y *el inspector técnico*, porque le pone color a las pizarras del onboarding.

### El portero: la Policy

Te vas a la pestaña **Policies** y creas una nueva, por ejemplo `cimd-policy`. Esta Policy mira las peticiones de login que llegan y filtra si "esto huele a CIMD" antes incluso de descargar el JSON.

- ¿El `client_id` es una URL HTTPS válida? Si no, fuera.
- ¿El dominio de esa URL está en mi lista blanca (`client-id-uri-allow-permitted-domains`)? Si no, fuera.

Esto es lo que te blinda contra SSRF a nivel del primer filtro. La lista blanca contiene cosas como `vscode.dev`, `cursor.com`, `claude.ai` y demás dominios de proveedores que sí queremos aceptar. Cualquier otra cosa se va a tomar por culo con un `403`.

Y por último, en la propia Policy, en la sección de **Profiles**, le enlazas el Profile que vas a crear ahora mismo. Sin ese enlace la Policy no hace nada útil, solo filtra el dominio del `client_id` y se queda tan ancha.

### El inspector técnico: el Profile

Te vas a la pestaña **Profiles** y creas otro, por ejemplo `cimd-profile`. Aquí dentro añades el ejecutor `client-id-uri-validation` (o el nombre que use tu versión exacta de Keycloak) y configuras la lista blanca de dominios permitidos para las URIs internas del JSON: `cimd-allow-permitted-domains`.

Si la Policy dejó pasar la petición, entra el Profile. Este sí se va a internet, descarga el JSON, y empieza a inspeccionar:

- ¿Tiene `client_name` y `redirect_uris`? Lo mínimo de lo mínimo.
- ¿Las URLs de **redirect_uris** apuntan a dominios permitidos en `cimd-allow-permitted-domains`?
- ¿Y las URLs **secundarias** (`logo_uri`, `tos_uri`, `policy_uri`, `jwks_uri`)? **Todas. También las que parecen inocuas.**

Si todo cuadra, crea (o actualiza) el cliente compartido. Si no, error y para casa.

## El error que te vas a comer (lo veo venir)

Hay un error con el que vamos a chocar todos los que pongamos esto en producción. Lo dejo aquí escrito para que cuando te pase, llegues por Google y te ahorre dos horas:

```text
Invalid Client ID: domain not allowed.
```

Te lo lanza Keycloak y te quedas mirando la pantalla con cara de pánfilo, porque **el dominio del `client_id` SÍ está en la lista blanca**, lo has comprobado tres veces.

La trampa es que el inspector técnico no se conforma con el dominio del `client_id`. Audita **TODAS las URIs declaradas dentro del JSON**. Y la mayoría de IDEs sirven su descripción desde un dominio (digamos `vscode.dev`) pero alojan el logo, los términos de uso y la política de privacidad en **otro dominio del mismo proyecto** (`code.visualstudio.com`).

Y eso te deja con una situación así de ridícula:

- `client_id`: `https://vscode.dev/oauth/client-metadata.json` → OK, dominio en lista.
- Dentro del JSON: `"logo_uri": "https://code.visualstudio.com/assets/logo.png"` → **NO** está en la lista del Profile. Puerta cerrada.

Lo que tienes que hacer es abrir la URL del JSON en tu navegador, mirar qué otros dominios cuela el cliente, y añadirlos a la propiedad `cimd-allow-permitted-domains` del Profile. Es un proceso manual y un poco tedioso, pero solo lo haces una vez por proveedor. Luego ya nunca más.

## Cómo se relaciona con MCP

CIMD es una pieza que MCP necesita para funcionar a escala. El protocolo da por hecho que tu servidor MCP va a recibir conexiones de **clientes que tú no controlas** (IDEs, agentes, herramientas de terceros). Si cada uno de ellos tuviera que pasar por el aro de "haz un ticket a SRE para que te dé de alta", esto no escalaba ni queriendo.
DCR daba esa flexibilidad pero te dejaba la BBDD llena de clones. CIMD da la misma flexibilidad **sin clones**, porque el `client_id` ya es único por aplicación: es una URL global, y solo hay una URL por aplicación.

Hay otra cosa que mola: **CIMD encaja con la web tal y como existe**. No requiere un nuevo protocolo, no requiere nuevos endpoints en el lado del cliente, no requiere certificados especiales. Lo que requiere es que pongas un JSON detrás de una URL HTTPS. Si tienes un servidor web, ya sabes hacer eso. Esto baja muchísimo la barrera de entrada para que cualquier IDE pequeñito implemente OAuth contra MCP correctamente.

## Lo que creo que pasará en los próximos 18 meses

- Los IDEs grandes (VS Code, Cursor, Claude Desktop, JetBrains) van a tener su CIMD publicado de serie. Algunos ya lo hacen.
- Alguien intentará hacer un ataque SSRF muy creativo. Saldrá un CVE. Todos pondremos nuestras whitelists al día y juraremos que ya las teníamos así.
- DCR se quedará para los casos en los que el cliente es genuinamente único (integraciones corporativas). El 95% del tráfico MCP irá por CIMD.

## Para terminar

CIMD es un buen ejemplo de que **a veces el problema no se resuelve con más código sino con menos**. DCR generaba basura porque cada cliente generaba un registro. CIMD no genera basura porque cada *aplicación* es un registro único, decidido por el dueño de la aplicación. Es el mismo problema mirado desde otro ángulo, y la solución encaja con cómo funciona la web de toda la vida.

Si estás montando algo nuevo en MCP, este es el camino. Si tienes DCR funcionando, no migres por modas, pero ten claro que el spec va para aquí.

Y si te encuentras con que el inspector técnico te bloquea porque el logo del IDE está en otro dominio, respira hondo. Le pasa a todos. La primera vez es una hora, la segunda son cinco minutos.
