[English](FASTDL.md)

# FastDL: darles archivos propios (sonidos, modelos) a los jugadores

Cuando el servidor usa archivos que los jugadores no tienen (por ejemplo, nuestros sonidos del karma
kill), los jugadores los tienen que descargar. Sin FastDL los descargan del propio servidor del juego,
lo que es lento y puede trabar la entrada. Con **FastDL** los descargan de un servidor web normal, que
es mucho más rápido.

Esta guía arma FastDL en una computadora con IP pública (por ejemplo en casa), en **Linux o Windows**.
El servidor web no tiene que ser la misma máquina que el servidor del juego.

## Cómo funciona

1. Un plugin le dice al juego que hace falta un archivo (`AddFileToDownloadsTable`), por ejemplo
   `sound/lefordianos/karma/fall1.wav`.
2. El servidor del juego les manda a los jugadores su `sv_downloadurl`, por ejemplo `http://203.0.113.5:27080/`.
3. A un jugador que no tiene el archivo se le descarga
   `http://203.0.113.5:27080/sound/lefordianos/karma/fall1.wav.bz2` (o el que no está comprimido si no
   hay `.bz2`), lo descomprime y entra.

Así que el servidor web solo necesita una carpeta ordenada **como `left4dead2/`**, que tenga solamente
los archivos propios.

## 1. Preparar los archivos

Crea una carpeta, por ejemplo `fastdl/`, con las mismas rutas que el juego:

```
fastdl/
└── sound/
    └── lefordianos/
        └── karma/
            ├── fall1.wav.bz2
            └── fall2.wav.bz2
```

Comprime cada archivo con **bzip2** (más chico, baja más rápido). Los originales sin comprimir van en el
**servidor del juego** (`left4dead2/sound/...`); el servidor web solo tiene las copias `.bz2`.

- **Linux:** `bzip2 -k fall1.wav` (crea `fall1.wav.bz2` y deja el original).
  Para toda una carpeta: `find fastdl -type f ! -name '*.bz2' -exec bzip2 -f {} \;`
- **Windows:** con [7-Zip](https://www.7-zip.org/): clic derecho → 7-Zip → *Añadir al archivo* →
  formato **bzip2**. O desde una terminal: `"C:\Program Files\7-Zip\7z.exe" a -tbzip2 fall1.wav.bz2 fall1.wav`

## 2. Correr un servidor web

Elige un puerto, por ejemplo **27080**. Sirve cualquier servidor web de archivos estáticos. Sirve
**solo** la carpeta `fastdl` (nunca la carpeta del servidor del juego) y desactiva el listado de carpetas.

### Linux

Prueba rápida (se apaga al cerrar la terminal):

```bash
python3 -m http.server 27080 --directory /srv/fastdl
```

Permanente, con nginx:

```bash
sudo apt install nginx
sudo mkdir -p /srv/fastdl && sudo cp -r fastdl/* /srv/fastdl/
sudo tee /etc/nginx/sites-available/fastdl >/dev/null <<'EOF'
server {
    listen 27080;
    root /srv/fastdl;
    autoindex off;
    location / { try_files $uri =404; }
}
EOF
sudo ln -s /etc/nginx/sites-available/fastdl /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo ufw allow 27080/tcp     # si usas ufw
```

### Windows

Prueba rápida, si tienes Python instalado:

```powershell
python -m http.server 27080 --directory C:\fastdl
```

Permanente, con [Caddy](https://caddyserver.com/download) (un solo `caddy.exe`, sin instalador):

```powershell
caddy file-server --root C:\fastdl --listen :27080
```

Para que arranque con Windows, crea una tarea programada que ejecute ese comando al iniciar, o usa un
programa que lo convierta en servicio, como [NSSM](https://nssm.cc/).

Abre el puerto en el firewall de Windows (PowerShell como administrador):

```powershell
New-NetFirewallRule -DisplayName "L4D2 FastDL" -Direction Inbound -Protocol TCP -LocalPort 27080 -Action Allow
```

## 3. Hacerlo accesible desde internet

1. **IP local fija:** en el router, reserva una IP para la computadora del servidor web (reserva DHCP),
   así no cambia.
2. **Abrir el puerto:** en el router, redirige **TCP 27080** a esa IP local (port forwarding).
3. **IP pública:** la ves en una página como whatismyip. Si tu proveedor la cambia cada tanto, usa un
   nombre de DNS dinámico gratis (por ejemplo [DuckDNS](https://www.duckdns.org/) o No-IP) con su
   programita que lo actualiza; después usa el nombre en vez de la IP.
4. Algunos proveedores ponen las conexiones de casa detrás de CGNAT (sin IP pública real); en ese caso
   abrir el puerto no funciona y haría falta un VPS o algo parecido.

## 4. Configurar el servidor del juego

En el `cfg/server.cfg` del servidor del juego:

```
sv_allowdownload 1                              // los jugadores pueden descargar archivos
sv_downloadurl "http://203.0.113.5:27080/"      // tu IP o nombre DNS; deja la / al final
```

Usa **`http://`**: los juegos Source viejos no descargan bien por `https://`.

Los jugadores tienen que permitir las descargas: Opciones → Multijugador → *Permitir contenido
personalizado del servidor* (en consola: `cl_downloadfilter all`).

## 5. Probarlo

- Desde **fuera de tu red** (por ejemplo un celular con datos móviles), abre
  `http://TU-IP:27080/sound/lefordianos/karma/fall1.wav.bz2`. Se tiene que descargar.
- Entra al servidor con un cliente limpio (o borra el archivo de tu carpeta `left4dead2/download/`) y
  revisa que la consola muestre la descarga.

## A tener en cuenta

- **Velocidad de subida:** todos los jugadores descargan de tu conexión; si tu subida es lenta, la
  entrada es lenta. Los sonidos pesan poco, así que normalmente no es problema.
- **Mantener las dos copias iguales:** si cambias un archivo en el servidor del juego y no en FastDL (o
  al revés), los jugadores tienen diferencias. Vuelve a copiar y comprimir después de cada cambio.
- **Seguridad:** solo la carpeta `fastdl` es pública. No apuntes el servidor web a la carpeta del
  servidor del juego ni a tus carpetas personales.
- **Tamaño de archivo:** quien descarga directo del servidor del juego (sin FastDL) está limitado por
  `net_maxfilesize` (en MB). FastDL no tiene ese límite.
