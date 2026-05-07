---
title: "Cómo le puse un Garbage Collector a los clientes OAuth de Keycloak"
slug: "keycloak-dcr-lifecycle-manager"
date: 2026-05-07T20:11:27+01:00
draft: false
description: "Si DCR te está llenando la base de datos de clientes fantasma, te cuento cómo construí un plugin SPI para Keycloak que los barre automáticamente."
tags:
  - "keycloak"
  - "oauth2"
  - "dcr"
  - "sre"
  - "java"
categories:
  - "auth"
---

En el [artículo anterior](/posts/dcr-dynamic-client-registration/) te contaba cómo DCR (Dynamic Client Registration) se había colado en nuestras vidas gracias al protocolo MCP. Y cómo, por diseño, me estaba llenando la base de datos de Keycloak de _clientes basura_.

Cursor, Claude, Zed y toda la tropa de IDEs con IA se registran a sí mismos. Cada vez que un desarrollador borra la caché, cambia de portátil o parpadea fuerte, ¡pum!, un cliente OAuth nuevo que nunca se va a volver a usar y que se queda ahí, cogiendo polvo.

Te dije que "te jodes y te comes DCR". Y es verdad. Pero resulta que tengo un TOC muy fuerte con la basura digital. Ver tablas engordando con IDs huérfanos me da tics en el ojo. Así que hice lo que hace cualquier persona de bien cuando un sistema genera residuos y los que inventan estándares no piensan en las consecuencias: programarme mi propio Garbage Collector.

Y un aviso a navegantes: las empresas que no solucionen esto van a tener un problema muy gordo en los próximos meses. Cuando tus usuarios empiecen a enchufar tres o cuatro herramientas de IA distintas y las reinstalen un par de veces, tus bases de datos van a parecer un vertedero y a ver cómo auditas qué cliente legítimo tiene acceso a qué.

Pero como aquí estamos para ayudar, he decidido abrir la solución. Lo he publicado como open source. Se llama [`keycloak-dcr-lifecycle-manager`](https://github.com/freepik-company/keycloak-dcr-lifecycle-manager) y es un plugin (SPI) para Keycloak que programé para enlazar los clientes con los usuarios y purgar lo que sobra. Vamos a ver cómo le di la vuelta a esto.

## El problema de fondo: OAuth2 no sabe de quién es el cliente

Cuando un IDE hace un `POST` al endpoint de DCR, Keycloak crea el cliente y devuelve las credenciales. En ese milisegundo, el cliente existe en la base de datos, pero **no está enlazado a ninguna persona**. El protocolo OAuth2 asume que los clientes son entidades independientes (como "La app de Spotify"), no instancias efímeras atadas a un humano.

Ese enlace solo ocurre lógicamente cuando el usuario abre el navegador, se autentica y autoriza al cliente.

Esto me dejaba con tres tipos de basura:

1. **Los huérfanos puros:** El IDE registró el cliente, pero el usuario cerró la pestaña del login o le dio pereza terminar. Ese cliente jamás se usó.
2. **Los duplicados activos:** El mismo dev usando Cursor en el portátil del curro y en el PC de su casa. Dos clientes distintos que hacen exactamente lo mismo.
3. **Los zombis:** Clientes de IDEs que el usuario probó hace 6 meses, borró, y no volverá a usar en la vida.

## La solución: Un Event Listener en dos fases

Para arreglar este desaguisado, apliqué un concepto más viejo que el hilo negro: el clásico algoritmo de recolección de basura *Mark and Sweep* (Marcar y Barrer). 

Hacer un escaneo masivo de la tabla de clientes cada vez que alguien hace login para ver qué borramos es una receta fantástica para tumbar la base de datos en producción y quedarte sin curro. Las cosas pesadas no se hacen mientras el usuario espera mirando la pantallita. Así que diseñé el SPI dividiendo el trabajo en dos fases muy diferenciadas: primero le ponemos una pegatina a la basura, y luego pasamos el camión a recogerla.

### Fase 1: El Hot Path (Marcar y etiquetar)

El *hot path* (o camino crítico) es todo lo que ocurre en tiempo real mientras el usuario y el IDE están interactuando con Keycloak. Aquí la regla de oro es **no meter latencia**. No puedes hacer queries raras ni pararte a pensar. La idea es simplemente intervenir en los eventos estándar para "marcar" a los clientes como si les pusiéramos una etiqueta en la oreja.

- **Al registrar un cliente nuevo:** Cuando entra la petición inicial del IDE para darse de alta en el sistema, el plugin lo detecta y le escribe tres atributos tontos al cliente: una marca para saber que viene de DCR, la fecha de creación, y una "huella dactilar" (un código único generado a partir de las URLs de redirección y el nombre del cliente). Esta huella es vital porque me permite saber que dos clientes distintos son en realidad "la misma app" instalada en sitios diferentes.
- **Al iniciar sesión:** Cuando el usuario pone su contraseña y entra con éxito, el plugin vuelve a mirar. Si el cliente que está usando tiene la marca de DCR, le añade dos datos más: el ID del usuario que acaba de entrar y la fecha del último uso.

Ya está. Cero escaneos, cero borrados en el hot path. Solo dos llamadas inofensivas a `setAttribute` para tener los datos marcados.

### Fase 2: El Garbage Collector asíncrono

Si la Fase 1 era poner pegatinas, la Fase 2 es el camión de la basura que pasa de madrugada. Como ya tenemos a todos los clientes marcados con su fecha de uso, la persona a la que pertenecen y su huella dactilar, ahora sí podemos hacer el trabajo sucio en diferido sin penalizar la experiencia de nadie. 

Aquí viene la magia. Configuré una tarea programada (`TimerProvider` de Keycloak) que se despierta cada hora en segundo plano. Para evitar que en un cluster en HA todos los nodos se pongan a borrar a la vez como pollos sin cabeza, uso el `ClusterProvider` para pillar un lock distribuido. Solo un nodo ejecuta la purga.

El recolector aplica estas reglas:

1. **Purga de huérfanos:** Busca clientes generados por DCR que lleven más de 24 horas creados y que **no estén asociados a ninguna persona**. A la calle. Claramente eran intentos fallidos de login que se quedaron a medias.
2. **Desfragmentación (Estrategia "Last wins"):** Agrupa los clientes usando a su dueño y la huella dactilar de la app. Es decir, junta "todas las veces que Juan instaló Cursor". Si Juan tiene tres instalaciones, el recolector se queda con la más reciente y aniquila las otras dos. Así siempre tienes exactamente un cliente activo por persona y aplicación.

Si no te gusta ser tan agresivo borrando, le metí al plugin soporte para una estrategia de **"Periodo de gracia"** donde solo borra clientes que lleven X días sin usarse. Todo se configura pasándole variables de entorno al contenedor de Keycloak.

## La belleza de las cosas invisibles

Al final, este SPI hace exactamente lo que debería hacer un buen código: barrer la mierda sin que nadie tenga que pedirlo y sin que el usuario note nada raro.

Si estás exponiendo servicios mediante MCP y te está pasando esto (y si no te pasa ahora, te va a pasar, créeme), no hace falta que reinventes la rueda ni que escribas scripts bash cutres. Bájate el `.jar` o compílalo tú mismo desde [freepik-company/keycloak-dcr-lifecycle-manager](https://github.com/freepik-company/keycloak-dcr-lifecycle-manager), mételo en tu carpeta `providers/`, actívalo en los Event Listeners de tu realm, y deja que la basura se saque sola.
