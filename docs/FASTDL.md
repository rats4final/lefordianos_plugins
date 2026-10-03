[Español](FASTDL.es.md)

# FastDL: serving custom files (sounds, models) to players

When the server uses files players don't have (our karma kill sounds, for example), players must
download them. Without FastDL they download from the game server itself, which is slow and can
stall joining. With **FastDL** they download from a normal web server instead, which is much faster.

This guide sets up FastDL on a computer with a public IP (e.g. at home), on **Linux or Windows**.
The web server doesn't have to be the same machine as the game server.

## How it works

1. A plugin tells the game a file is needed (`AddFileToDownloadsTable`), e.g.
   `sound/lefordianos/karma/fall1.wav`.
2. The game server sends players its `sv_downloadurl`, e.g. `http://203.0.113.5:27080/`.
3. A player missing the file downloads `http://203.0.113.5:27080/sound/lefordianos/karma/fall1.wav.bz2`
   (or the uncompressed one if there's no `.bz2`), unpacks it and joins.

So the web server just needs a folder laid out **like `left4dead2/`**, containing only the custom files.

## 1. Prepare the files

Make a folder, e.g. `fastdl/`, mirroring the game paths:

```
fastdl/
└── sound/
    └── lefordianos/
        └── karma/
            ├── fall1.wav.bz2
            └── fall2.wav.bz2
```

Compress each file with **bzip2** (smaller, faster downloads). Keep the uncompressed originals on the
**game server** (`left4dead2/sound/...`); only the web server gets the `.bz2` copies.

- **Linux:** `bzip2 -k fall1.wav` (makes `fall1.wav.bz2` and keeps the original).
  For a whole folder: `find fastdl -type f ! -name '*.bz2' -exec bzip2 -f {} \;`
- **Windows:** with [7-Zip](https://www.7-zip.org/): right-click → 7-Zip → *Add to archive* →
  Archive format **bzip2**. Or from a terminal: `"C:\Program Files\7-Zip\7z.exe" a -tbzip2 fall1.wav.bz2 fall1.wav`

## 2. Run a web server

Pick a port, e.g. **27080**. Any web server that serves static files works. Serve **only** the
`fastdl` folder (never the game server folder) and turn directory listing off.

### Linux

Quick test (stops when you close the terminal):

```bash
python3 -m http.server 27080 --directory /srv/fastdl
```

Permanent, with nginx:

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
sudo ufw allow 27080/tcp     # if you use ufw
```

### Windows

Quick test, if Python is installed:

```powershell
python -m http.server 27080 --directory C:\fastdl
```

Permanent, with [Caddy](https://caddyserver.com/download) (a single `caddy.exe`, no installer):

```powershell
caddy file-server --root C:\fastdl --listen :27080
```

To start it with Windows, make a scheduled task that runs that command at logon/startup, or use a
service wrapper such as [NSSM](https://nssm.cc/).

Open the port in the Windows firewall (PowerShell as administrator):

```powershell
New-NetFirewallRule -DisplayName "L4D2 FastDL" -Direction Inbound -Protocol TCP -LocalPort 27080 -Action Allow
```

## 3. Make it reachable from the internet

1. **Fixed local IP:** in the router, reserve an IP for the computer running the web server
   (DHCP reservation), so it doesn't change.
2. **Port forwarding:** in the router, forward **TCP 27080** to that local IP.
3. **Public IP:** find it at a site like whatismyip. If your ISP changes it from time to time, use a
   free dynamic DNS name (e.g. [DuckDNS](https://www.duckdns.org/) or No-IP) and its small updater
   program; then use the name instead of the IP.
4. Some ISPs put home connections behind CGNAT (no real public IP); then port forwarding can't
   work and you'd need a VPS or similar instead.

## 4. Tell the game server

In the game server's `cfg/server.cfg`:

```
sm_cvar sv_allowdownload 1                      // players may download files
sm_cvar sv_downloadurl "http://203.0.113.5:27080/" // your IP or DNS name; keep the trailing /
```

Use `sm_cvar`: L4D2 hides these two from cfg files and answers "Unknown command" without it.

Use **`http://`**: older Source games don't download reliably over `https://`.

Players need downloads allowed on their side: Options → Multiplayer → *Allow custom server content*
(console: `cl_downloadfilter all`).

## 5. Test it

- From **outside your network** (e.g. a phone on mobile data), open
  `http://YOUR-IP:27080/sound/lefordianos/karma/fall1.wav.bz2`. It should download.
- Join the server with a clean client (or delete the file from your own `left4dead2/download/`
  folder) and check the console shows the download.

## Things to keep in mind

- **Upload speed:** every player downloads from your connection; a slow upload means slow joins.
  Sounds are small, so this is usually fine.
- **Keep both copies in sync:** a file changed on the game server but not on FastDL (or the other
  way round) gives players a mismatch. Re-copy and re-compress after any change.
- **Security:** only the `fastdl` folder is public. Don't point the web server at your game server
  or home folders.
- **File size:** players downloading directly from the game server (no FastDL) are limited by
  `net_maxfilesize` (MB). FastDL doesn't have that limit.
