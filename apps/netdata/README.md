# Netdata

Netdata fournit la vue technique temps réel du serveur : CPU, mémoire, disques,
réseau, processus, unités systemd et consommation des cgroups Docker. Uptime
Kuma garde un rôle différent : il vérifie la disponibilité des services depuis
leur point d'accès.

## Réseau et accès

- Netdata ne publie aucun port hôte ; Caddy est son seul proxy sur le réseau
  Docker externe `homelab-proxy` ;
- l'accès LAN passe par `https://netdata.home.arpa` après résolution de ce nom
  vers `192.168.1.69` et confiance dans l'autorité Caddy ;
- l'accès distant privé passe par
  `https://homelab.tail239aaa.ts.net:8444`, exclusivement dans le tailnet ;
- aucun accès Internet, Funnel, API Docker TCP ou socket Docker n'est autorisé.

## Ce que Netdata peut voir

Les montages de `/proc`, `/sys`, de la racine de l'hôte et de D-Bus sont tous en
lecture seule. Ils donnent les métriques de l'hôte et des unités systemd. Le
conteneur utilise le namespace PID de l'hôte pour associer les processus et les
cgroups à ces métriques.

Le socket Docker n'est volontairement **pas** monté. Même un proxy de socket
présenté comme lecture seule peut autoriser, via des endpoints GET, la lecture
de journaux ou de fichiers d'autres conteneurs. Netdata affiche donc les
ressources des workloads Docker via les cgroups, sans disposer de leur inventaire
ou de leurs données. Portainer reste l'inventaire et l'outil d'administration
des conteneurs.

## Données et restauration

Les volumes suivants conservent configuration et historique local :

- `netdata-config` ;
- `netdata-lib` ;
- `netdata-cache`.

Ils ne sont pas encore inclus dans une sauvegarde automatisée. Le stack est
suivi par Portainer depuis `apps/netdata/compose.yaml` : modifier Git, relire,
committer puis laisser GitOps redéployer. Ne jamais modifier son compose dans
l'éditeur Web de Portainer.
