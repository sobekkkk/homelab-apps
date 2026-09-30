# Uptime Kuma

Supervision via Uptime Kuma, accessible par Caddy sur le LAN et par le relais
privé Tailscale. Aucun accès public Internet n'est prévu.

## Réseau

- Caddy publie `192.168.1.69:443` et son listener Netdata dédié sur
  `192.168.1.69:8444` ;
- Uptime Kuma n'a aucun port hôte ; il n'est jamais publié sur le LAN ou
  Internet ;
- le réseau `uptime-kuma-net` reste interne et relie Kuma à Caddy ;
- Kuma rejoint aussi `kuma-egress`, un bridge NAT géré par ce stack,
  pour la résolution DNS externe et les notifications HTTPS ;
- `homelab-proxy` est créé par l'infrastructure NixOS pour les services
  derrière le proxy ; Kuma ne rejoint pas ce réseau partagé ;
- l'adresse Tailscale sur TCP/443 reste réservée à Portainer Serve.

Tailscale Serve relaie Kuma à travers Caddy vers
`https://homelab.tail239aaa.ts.net:8443`, uniquement aux appareils autorisés du
tailnet. Ce relais termine TLS avec le certificat Tailscale et n'utilise jamais
Tailscale Funnel.

## Notifications Discord

Le réseau de sortie est une exception explicite à l'isolement Internet par
défaut. Aucun port supplémentaire, routage Tailscale, socket Docker ou capacité
Linux n'est ajouté. Caddy ne rejoint pas `kuma-egress`.

Ce bridge n'est **pas** une liste blanche Discord : Kuma peut initier d'autres
connexions sortantes, y compris vers le LAN si les règles hôte les permettent.
Limiter seulement Discord demanderait un proxy de sortie ou un filtrage
supplémentaire avec gestion DNS, dépendances, tests et maintenance. On conserve
ici un réseau Docker standard pour éviter une dépendance de plus et des listes
d'IP Discord fragiles. Les contrôles d'accès LAN/Tailscale existants restent
inchangés ; aucun transfert de port ne doit être ajouté au routeur.

Le webhook est saisi uniquement dans la configuration de notification Kuma.
Il ne doit apparaître ni dans le Compose, ni dans Git, ni dans les captures ou
journaux partagés. Le volume `uptime-kuma-data` doit être traité comme sensible.
Une URL déjà publiée doit être révoquée dans Discord.

### Vérification après GitOps

1. Dans Portainer, vérifier que `uptime-kuma-gitops` a récupéré le commit et
   que Kuma appartient à `uptime-kuma-net` et au réseau `kuma-egress` du stack.
2. Vérifier que les sondes existantes restent vertes et que Kuma n'a aucun
   port publié sur l'hôte.
3. Dans Kuma, ouvrir la notification Discord existante puis **Tester**.
   Vérifier la réception dans le salon prévu. Ce test envoie un vrai message.

Si `ENOTFOUND` persiste après déploiement, vérifier la résolution DNS du
conteneur et le DNS de l'hôte ; ne pas remplacer le nom Discord par une IP,
désactiver TLS ou modifier le webhook pour contourner ce défaut réseau.

### Retour arrière

Revenir au commit précédent via Git puis redéployer le même stack. Ne pas
supprimer les volumes : les sondes et identifiants restent conservés. Le retour
à l'isolement initial empêche de nouveau les notifications Internet.

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

Les sondes internes de Kuma utilisent `https://caddy/health/kuma`,
`https://caddy/health/portainer` et, après le déploiement Netdata,
`https://caddy/health/netdata`, avec l'erreur TLS ignorée. Ces endpoints
réservent le trafic à Docker et évitent les redirections vers les noms
`.home.arpa`; aucun en-tête HTTP personnalisé n'est requis. Le vhost `caddy`
ne sert qu'à cette supervision interne et n'est pas publié sur l'hôte.
