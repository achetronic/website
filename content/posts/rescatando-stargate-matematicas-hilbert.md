---
title: "Rescatando Stargate a base de matemáticas (y envolventes de Hilbert)"
slug: "rescatando-stargate-matematicas-hilbert"
date: 2026-06-08T10:00:00+01:00
draft: false
description: "Cómo usar procesamiento de señales para sincronizar automáticamente audios de distintos idiomas en un vídeo y por qué la IA no sirve para esto."
tags:
  - "ffmpeg"
  - "audio"
  - "math"
  - "signal-processing"
categories:
  - "ingeniería"
---

Me encanta Stargate. Su universo, su lore, todo. La he visto como seis veces entera a lo largo de mi vida y hace años la tenía bien guardada en mis discos duros. En algún momento la perdí, y cuando quise recuperarla, me di cuenta de que conseguir la serie original en buena calidad y en español, viviendo en Canarias, era misión imposible por la típica pesadilla de los envíos a las islas. Tengo una hermana en Madrid que podría hacerme de proxy, pero paso de molestarla para gilipolleces.

Al final conseguí juntar las piezas por mi cuenta: por un lado, un ripeo de televisión antiguo con una calidad de vídeo malísima pero con las voces en español intactas. Por otro lado, unos archivos en inglés sacados de Blu-Ray con una calidad de imagen de 1080p espectacular.

Momento de aclarar una cosa porque ya veo a la gente subiéndoseme al cuello como orcos del Señor de los Anillos: hablo inglés y he visto la serie en su idioma original, pero en este caso concreto, me gusta mucho más su doblaje en español. Los doblajes en España son muy buenos y a esta serie le sientan genial. Básicamente quería esa mezcla de vídeo impecable en inglés con mi audio de toda la vida.

El problema es que Stargate Atlantis tiene 5 temporadas. Son 100 capítulos y no iba a hacer la sincronización a mano metiendo pistas en Premiere (o en el Kdenlive que uso ahora) y ajustando fotogramas a ojo. Había que tirar de código.

## La tentación de la Inteligencia Artificial

Hoy en día, el primer instinto que tenemos todos es tirarle el problema a una IA y que se joda. El plan parecía perfecto, verás, pasas la pista en inglés y la pista en español por un modelo de transcripción, sacas los textos con marcas de tiempo, buscas dónde coincide el significado de las frases y calculas la diferencia matemática.

Repite conmigo: eso no funciona.

El problema de hacer transcripciones con IA para buscar sincronía fina es que el cine tiene canciones largas, silencios dramáticos y escenas de acción sin diálogo. Cuando los modelos de IA pasan mucho tiempo escuchando ruido sin hablar, los "timeouts" internos se desajustan y el reloj de la transcripción empieza a patinar. Con Gemini, que ahora mismo es el modelo que mejor hace este tipo de tareas, las marcas de tiempo acaban arrastrando un error progresivo que revienta cualquier intento de lograr una sincronización labial decente.

Entonces, como la IA no nos servía, había que volver a las matemáticas puras, esas que no le gustan a Alva Majo, creador de videojuegos indie (te quiero, Alva, no me mates, veo todos tus vídeos).

## El dolor de mezclar Televisión y Blu-Ray

Como comprenderás, editar los vídeos de mi canal no requiere que yo tenga los conocimientos de cine de Tim Burton. Algo sabía, claro, porque youtuber y porque ingeniero en electrónica (escrito así, en moderno). Con el procesamiento de señales jugaba muy a menudo, pero hasta ahora no se me había ocurrido mezclar ambos mundos.

El super plan de automatizar el proceso necesita que entiendas primero por qué dos audios que son del mismo capítulo no encajan sin más cuando los pones uno encima del otro.

El resumen rápido es este:

- El audio español viene de la tele europea, que emite a 25 fps (formato PAL).
- El Blu-Ray americano va a 23.976 fps (formato NTSC).
- El audio español va acelerado (el famoso "PAL speedup"). Las voces suenan más de pitufo y el capítulo dura menos. Hay que usar FFmpeg para corregirlo y que no se note.
- A esto súmale las diferencias de edición: en Yankee-landia muchos capítulos empiezan con un resumen del anterior y que en España no, hay escenas que se censuran, pitidos publicitarios que en España cortan, etc.

Entonces, el proceso lógico que tiene que seguir nuestro programa es más o menos el siguiente:

- Corregir el formato PAL
- Desnudar el sonido hasta encontrar su ritmo
- Ignorar los resúmenes iniciales
- Buscar el desfase en segundos
- Meterle un retraso al audio español
- Empaquetarlo de nuevo en el archivo `.mkv`

## El Radar Acústico (Matemáticas al rescate)

No podemos comparar el audio a lo bruto comparando ondas, porque "Hello" y "Hola" tienen ondas distintas. Así que hay un truco muy útil que es sacar la **Envolvente de Hilbert**. En pocas palabras, extrae la silueta de la energía del sonido. Da igual el idioma, si hay una explosión o un portazo, la montaña que dibuja la gráfica es idéntica en inglés y en castellano.

Luego hay que depurar un poco esa señal quitando los graves por debajo de 300Hz. Piensa que a bajas frecuencias suenan normalmente ruidos ambientales como el viento, zumbidos de motores espaciales y todas esas cosas que ahora mismo no nos sirven. Buscamos sonidos característicos, así que el relleno hay que obviarlo.

Después toca normalizar la señal para que los silencios valgan cero y destaquen los picos. Esos picos son los que nos interesan, papu, porque son los típicos golpes de puertas, disparos, explosiones... Y llámame loco, pero la dinamita suena igual en inglés y en español.

Ahora bien, ya tenemos una señal lo suficientemente depurada como para saber dónde ponerla, pero ¿recuerdas las diferencias de edición que comenté? Pues eso hace que no puedas poner un audio encima del otro y ya. Tienes que aislar una ventana de unos pocos minutos, e irla moviendo a lo largo del tiempo para saber si se mantiene estable o si de repente le empiezan a pasar cosas raras: un retraso constante, una deriva progresiva, un trozo cortado, etc.

Básicamente, el algoritmo se desliza como un **escáner** cogiendo bloques de 3 minutos (el minuto 3, luego el 6, luego el 9...). Así evita los "Previously On" engañosos del principio. Esto te da una radiografía perfecta de lo que está pasando entre el vídeo inglés y el español:

- Si el desfase es siempre `+2.0s` en todos los tramos, perfecto. Es simplemente un logo al principio de la tele española. Se arregla con un retraso fijo.
- Si el desfase va haciendo `+1.0s`, `+2.0s`, `+3.0s`, los framerates no cuadran y el audio se está "resbalando".
- Si da un salto brutal de golpe, la televisión censuró o cortó una escena y toca fraccionar el audio.

## La moraleja y el regalo

Es un proceso bastante universal, así que te puede servir para preservar todas esas piezas de cultura audiovisual que tarde o temprano se acabarán perdiendo. Piensa que los gustos de las generaciones cambian, y la época de las grandes _space opera_ está llegando a su fin con las cancelaciones de Stargate Universe en la segunda temporada y The Expanse, o los bajones de audiencia de Doctor Who.

Automatizar esto me ha salvado de ajustar 100 capítulos a mano. Y para que este rescate no se quede solo en mi disco duro, he empaquetado todo el proceso, el filtrado y las matemáticas en una **Skill** para tu agente de IA.

Si usas asistentes, que yo sé que los usas, aquí te dejo la receta. Solo tienes que meterla en tu directorio de skills y pedirle que "sincronice la serie":

```yaml
---
name: audio_sync_en
description: Expert skill in mathematical synchronization of audio tracks (TV vs Blu-Ray) using the Hilbert envelope and Normalized Cross-Correlation (NCC).
---

# Mathematical Audio Synchronizer (NCC & Hilbert)

You are an expert in the analysis and synchronization of audio tracks from different sources (typically PAL TV rips at 25fps vs NTSC Blu-Rays at 23.976fps). You never trust that the audio will magically align; you always apply a scientific approach based on signal processing.

## Your Mathematical Arsenal

You do not use `scipy.signal.correlate` in its raw form because it generates false peaks (the DC pedestal issue). **Always** use the following Python workflow:

1. **Speed Correction (FFmpeg):** If the source is PAL (25fps) and the destination is NTSC (23.976fps), apply pitch and time correction during extraction: `asetrate=ORIGINAL_SR*24000/25025`.
2. **High-Pass Filter:** Extract to mono WAV at 8000Hz and apply a Butterworth filter `> 300Hz` to clean up useless low frequencies (e.g., engine hums, wind).
3. **Hilbert Envelope:** Calculate `np.abs(signal.hilbert(audio))` to get the energy silhouette.
4. **Z-Score (Critical):** Downsample the envelope to 100Hz (`signal.decimate`), apply a slight smoothing, and standardize it: `(env - env.mean()) / env.std()`. This is vital to kill the low-frequency pedestal and avoid flat correlations.
5. **Normalized Cross-Correlation (NCC):** The correlation peak must yield an NCC > 0.4, and the ratio between the main peak and the second highest peak (outside a ±2s window) must be `> 1.8`. Otherwise, the match is garbage.

## Strict Procedure

Never mux a file without mathematically validating that the waveforms align.

1. **Local Scanning (Anti-Intros):**
   Never compare the first 15 minutes globally. Differences in logos or "Previously On" recaps will break the algorithm.
   Extract the audio and scan **3-minute local windows** (e.g., min 3 to 6, min 6 to 9, min 12 to 15) using a maximum search lag of `±40 seconds`.
2. **Drift Diagnosis:**
   *   If the lag is **constant** throughout the episode (e.g., always `+2.0s`): Green light. Apply that global offset.
   *   If the lag **progressively grows**: You have a framerate/pitch issue (drift). Review your `asetrate` multipliers.
   *   If the lag **jumps abruptly**: There's a censored scene or removed ad break. You must segment the audio and sync in parts.
   *   If there are no solid peaks (NCC < 0.2): **Stop**. The episodes are mismatched (the TV broadcast order differs from the Blu-Ray). Write a script that cross-checks the first 10 minutes of that audio against adjacent episodes in the season until you find a `MATCH` (ratio > 1.8).

## Final Packaging (Muxing)

Once you have confirmed the `LAG` in seconds and verified it across multiple time windows throughout the episode:

*   If the source audio is **ahead** (`LAG < 0`): Apply a delay.
    `filter_complex: "[0:a]adelay=DELAY_IN_MS:all=1[out]"`
*   If the source audio is **behind** (`LAG > 0`): Trim the beginning.
    `filter_complex: "[0:a]atrim=start=LAG_IN_SEC,asetpts=PTS-STARTPTS[out]"`

Always copy the video and subtitle streams without re-encoding (`-c:v copy -c:s copy`), encode the synced audio to AC3 (`-c:a:X ac3 -b:a:X 256k`), and update the language metadata.
```
