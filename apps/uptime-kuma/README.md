# Uptime Kuma

Supervision locale via Uptime Kuma, publiée par Caddy uniquement sur le LAN.

## Réseau

- Caddy écoute seulement sur `192.168.1.69:443` ;
- Uptime Kuma écoute seulement sur `127.0.0.1:3001` ; il n'est jamais publié
  sur le LAN ou Internet ;
- le réseau `uptime-kuma-net` est interne ;
- `homelab-proxy` est créé par l'infrastructure NixOS et sert seulement au
  proxy vers Portainer ;
- l'adresse Tailscale sur TCP/443 reste réservée à Portainer Serve.

Tailscale Serve relaie Kuma depuis cette boucle locale vers
`https://homelab.tail239aaa.ts.net:8443`, uniquement aux appareils autorisés du
tailnet. Ce relais termine TLS avec le certificat Tailscale et n'utilise jamais
Tailscale Funnel.

## Données et exploitation

Les volumes nommés sont intentionnellement stables afin qu'une migration du
stack conserve les données :

- `uptime-kuma-data` ;
- `uptime-kuma-caddy-data` ;
- `uptime-kuma-caddy-config`.

Ils ne sont pas encore sauvegardés. Ne pas y placer de donnée irremplaçable
avant la mise en place et le test d'une sauvegarde.

Le stack est lu par Portainer depuis `apps/uptime-kuma/compose.yaml`. Toute
modification doit être commitée puis laissée au mécanisme GitOps ; ne pas
modifier le compose dans l'éditeur Web de Portainer.
