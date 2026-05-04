---
title: "DCR, el estándar OAuth que se nos coló por casa"
slug: "dcr-dynamic-client-registration"
date: 2026-05-04T12:00:00+02:00
lastmod: 2026-05-04T12:00:00+02:00
draft: true
description: "Qué es Dynamic Client Registration, cómo lo aprovecha MCP para que cualquier IDE se autentique solo, y por qué dejaba la base de datos hecha unos zorros."
tags:
  - "oauth2"
  - "mcp"
  - "keycloak"
  - "sre"
  - "auth"
categories:
  - "auth"
---

Si llevas algún tiempo metido en sistemas con identificación delegada (Keycloak, Auth0, Okta, lo que sea), sabes que registrar un cliente OAuth es una de esas tareas burocráticas a las que nadie le presta atención hasta que toca hacerlo treinta veces seguidas.

Vas al panel de admin, rellenas el formulario, copias el `client_id`, lo pegas en la app, te das cuenta de que se te olvidó añadir el `redirect_uri`, vuelves, y así hasta que te jubilas.

DCR (Dynamic Client Registration) nació para que esa fricción dejara de ser tu problema.

Y luego MCP (Model Context Protocol) lo adoptó porque tenía sentido. Y luego DCR nos empezó a llenar la base de datos de clientes huérfanos como quien rellena un cubo con palomitas en el cine.

Pero vamos por partes.


## Qué es DCR

DCR está definido en la [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591) y, en cuatro palabras, dice esto: **un cliente OAuth puede registrarse a sí mismo** haciendo una petición HTTP a un endpoint del proveedor de identidad.

Sin formularios, sin tickets a SRE, sin esperar a que un admin esté de buenas.

El flujo es básicamente:

```http
POST /realms/mi-realm/clients-registrations/openid-connect HTTP/1.1
Host: auth.example.com
Content-Type: application/json

{
  "client_name": "Mi IDE Súper Guay",
  "redirect_uris": ["http://localhost:54321/callback"],
  "grant_types": ["authorization_code", "refresh_token"],
  "token_endpoint_auth_method": "none"
}
```

El servidor responde con algo así:

```json
{
  "client_id": "9f3a1e8c-7b22-4d11-bf66-2a4d1f0e7a98",
  "client_secret": "no-en-nuestro-caso-porque-somos-public-client",
  "client_id_issued_at": 1714820400,
  "redirect_uris": ["http://localhost:54321/callback"],
  "registration_access_token": "eyJhbG...",
  "registration_client_uri": "https://auth.example.com/realms/mi-realm/clients-registrations/openid-connect/9f3a1e8c-..."
}
```

Y ya está.

El cliente tiene su identidad. Puede iniciar el flujo de autorización como cualquier otra app de toda la vida. Si más adelante necesita actualizar sus datos, usa el `registration_access_token` y modifica su propio registro.

Sobre el papel pinta bien.


## Por qué MCP dijo que sí

[Model Context Protocol](https://modelcontextprotocol.io/) es el estándar que están empujando Anthropic y compañía para que los IDEs y agentes (Claude, Cursor, VS Code con su Copilot, lo que sea) hablen con servidores MCP: tu base de datos, tu Jira, tu Confluence interno, tu cluster de Kubernetes.

La idea es que tú expones un servidor MCP en tu empresa, y cualquier herramienta del usuario se conecta y consume datos contextualizados.

¿Y cómo se identifica esa herramienta? OAuth 2.0.

Pero claro, aquí entra el detalle que le dio sentido a DCR: el servidor MCP **no sabe quién va a conectarse**. Hoy es VS Code, mañana es Cursor, pasado es un IDE que ni existe todavía.

Pedirle al admin del Keycloak que dé de alta un cliente nuevo cada vez que sale un editor en Hacker News es absurdo.

La salida natural es que el cliente se registre solo. Que cada IDE, la primera vez que un usuario conecte, lance su `POST` y le devolvamos un `client_id`.

El usuario no se entera, el IDE no se entera, y SRE no se entera, que es como deben ser las cosas que funcionan bien.

Las primeras versiones del estándar MCP se basaron en esto. Y durante un tiempo fue la solución más limpia.


## El defecto que nadie vio venir (o sí, pero hicimos como que no)

Aquí viene la parte interesante, que es por la que probablemente has llegado a este post.

Imagina la siguiente escena, que no es ficción, es lo que vimos en producción:

1. Un dev instala Cursor. El IDE hace `POST` al endpoint de registro. Keycloak crea un cliente. ID generado: `aa11`.
2. El dev se cabrea con Cursor (le pasa a todo el mundo), borra la caché. Vuelve a abrir. Se vuelve a registrar. ID nuevo: `bb22`.
3. Cambia de portátil. Otro registro. `cc33`.
4. Reinstala el sistema operativo porque jugaba con Nix. `dd44`.
5. Multiplica esto por 200 desarrolladores en la empresa.
6. Multiplica por todos los IDEs distintos que cada uno prueba en una semana.

Y así acabas con **una base de datos llena de clientes OAuth fantasma**.

Nunca se vuelven a usar, ocupan espacio, ralentizan queries en la tabla `client`, ensucian los logs y, si te pones tiquismiquis con la auditoría, complican entender qué hay vivo y qué no.

Le llamamos *clientes basura*, que es como llamamos cariñosamente a estas cosas en el gremio.

¿Se puede limpiar? Sí, hay endpoints de des-registro y se puede tener un cronjob que purgue los que llevan X días sin tocarse. Pero eso significa:

- Mantener un script más.
- Decidir cuánto tiempo es "muerto" sin pillar a alguien que sí volverá la semana que viene.
- Tener cuidado de no borrar el del compañero que está de baja.

Y todo esto para resolver un problema que **no debería existir**.

El cliente "VS Code", lógicamente, es **uno**. No 14 000.


## Y luego está el otro problema: cualquiera puede registrarse

DCR, por defecto, es un endpoint público. Cualquier `POST` con un JSON razonable te da un cliente. Esto se aprovecha en dos sentidos malos:

- **Bots scraping**: alguien encuentra tu endpoint y empieza a registrar clientes fake para hacer ruido o para intentar luego un ataque de phishing usando un nombre creíble (`"client_name": "GitHub Official"`).
- **Recursos consumidos**: cada registro escribe en BBDD. Si te abren la mano un poco, te DDoSean por la puerta de atrás.

Para protegerlo hay varias estrategias.

Keycloak, para que conste, **sí tiene policies decentes para DCR**. Puedes configurar `client-registration-policies` que limiten el número máximo de clientes que se registran, las IPs de origen permitidas, los scopes que se les pueden asignar a los clientes creados, y un puñado de cosas más. Está bien resuelto.

Pero hay una pega importante con el filtrado por IP en Keycloak: **solo entiende de IPs sueltas, no de bloques CIDR**. Y Anthropic, OpenAI y compañía publican rangos enormes con notación `/16`, `/20`, lo que sea.

Si quieres autorizar `104.21.0.0/16` desde Keycloak tienes dos opciones, ambas malas: o expandes el CIDR a las 65 536 IPs y se lo metes una a una al endpoint de policies (que se va a quejar y con razón), o renuncias a filtrar por IP en el IdP.

El sitio natural para esto es el ingress, porque el ingress sí habla TCP/IP de verdad y entiende de CIDRs sin parpadear. En nuestro caso lo hace Istio con un `AuthorizationPolicy` que vive fuera de Keycloak. Si tu IP no está en la lista, te llevas un `403 Forbidden` antes de que la petición huela el pod del IdP.

```yaml
# AuthorizationPolicy de Istio (resumido)
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: keycloak-dcr-allowlist
spec:
  selector:
    matchLabels:
      app: keycloak
  action: ALLOW
  rules:
    - to:
        - operation:
            paths: ["/realms/*/clients-registrations/*"]
      from:
        - source:
            ipBlocks:
              # rangos publicados por proveedores
              - 160.79.104.0/23   # Anthropic
              - 104.21.0.0/16     # alguna saca de OpenAI
              # IP fija del NAT de la oficina
              - 81.45.32.7/32
```

Esto funciona genial **si los proveedores tienen IPs estables**. Anthropic publica un par fijas, Microsoft también.

Pero **OpenAI cambia rangos como quien cambia de calcetines**, y los publica en una página. Acabas montando un cronjob que se conecta a esa URL, parsea los CIDRs, y actualiza el `AuthorizationPolicy` automáticamente.

```bash
# El cron, a ojo de buen cubero
0 */6 * * * /opt/sre/sync-openai-cidrs.sh
```

Y cuando OpenAI decida un día publicar el JSON con otro formato sin avisar, el script peta y te enteras un viernes a las 19:00 porque algún dev no puede usar Codex.


## ¿Entonces DCR está muerto?

No. Para nada.

Y aquí hay dos cosas que importan a la vez.

La primera: para la mayoría de casos nuevos, **DCR no es la herramienta adecuada**. Para el patrón "miles de instalaciones del mismo IDE pidiendo cada una su clientazo", lo que tiene sentido es CIMD, que cuento en [el siguiente post](/posts/cimd-client-id-metadata-document/).

Pero la segunda es que **DCR sigue muy vivo**, y va a seguir vivo durante un buen rato. Hay varios motivos.

- El estándar MCP cambió, sí, pero la gente no actualiza en una semana. Hay literalmente miles de implementaciones que ya hablan DCR y a las que nadie les ha tocado el código todavía.
- A día de hoy hay clientes muy gordos que **no soportan CIMD**. Por ejemplo, **Claude Web** y la conexión MCP de **OpenAI Web** siguen yendo por DCR. Si tú apagas DCR mañana, esos usuarios dejan de poder conectar.
- DCR es trivial de implementar para el cliente: un `POST` con un JSON. CIMD requiere que tu cliente publique y mantenga un endpoint HTTPS, lo cual no todo el mundo está en condiciones de asumir.

Por eso lo que vemos en la práctica es una convivencia: **CIMD como estándar moderno, DCR como red de seguridad para todo lo que aún no se ha movido**.

Esto significa que vas a tener los dos endpoints abiertos durante meses, probablemente años. Y el de DCR, sí o sí, blindado a nivel de red.


## Tres aprendizajes que me llevo de toda esta historia

1. **Esto se veía venir desde la beta.** En cuanto vi en mi entorno de pruebas que cada cliente se creaba como un churrele recién hecho cada vez que tocabas algo, dije "esto explota". Si un protocolo genera basura por diseño, mal vamos.

2. **Algunos proveedores no publican bloques CIDR de salida**, y eso choca de frente con DCR. No puedes filtrar por origen con seriedad si el origen es opaco. Y dejar el endpoint de DCR abierto a internet entera es un error de novato, y no quieres ser novato con algo tan delicado como esto.

3. **Keycloak está adoptando estos protocolos antes que casi nadie.** DCR, CIMD, todas las extensiones de OAuth/OIDC que van saliendo, las suele tener implementadas y soportadas mucho antes que los productos comerciales. Si quieres un IdP potente, open source, y que te aguante las novedades del estándar sin tener que pagarle a nadie por adelantado, Keycloak es la elección natural.


Si vas a montar algo nuevo en 2026 hablando MCP, te jodes: te comes DCR y CIMD.

En un año probablemente con CIMD tengas suficiente (si no sale alguna otra idea portentosa de la cabeza de algún portentoso).

PD: Lee el [artículo sobre CIMD](/posts/cimd-client-id-metadata-document/), anda guapo.
