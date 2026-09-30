# Netdata

Netdata fournit la vue technique temps réel du serveur : CPU, mémoire, disques,
réseau, processus, unités systemd et consommation des cgroups Docker. Uptime
Kuma garde un rôle différent : il vérifie la disponibilité des services depuis
leur point d'accès.

## Réseau et accès

- Netdata ne publie aucun port hôte ; Caddy est son seul proxy sur le réseau
  Docker externe `homelab-proxy` ; le port 8444 publié par Caddy sur le LAN est
  réservé au relais Tailscale et ne donne pas un accès direct au conteneur ;
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

Le conteneur démarre avec des capacités supplémentaires pour
initialiser ses propres volumes puis basculer vers son utilisateur de service :
`CHOWN`, `DAC_OVERRIDE`, `FOWNER`, `SETGID`, `SETUID` et `SYS_PTRACE`. Elles ne
permettent pas d'écrire directement dans les montages hôte, qui restent en
lecture seule. Cela ne rend pas l'agent inoffensif : `SYS_PTRACE` et le namespace
PID hôte peuvent permettre des interactions avec des processus, et le montage
racine expose des fichiers sensibles. La réduction de ces accès reste à tester
avant de qualifier ce déploiement de durci. Un socket D-Bus monté en lecture
seule n'est pas une API limitée aux opérations de lecture.

Le socket Docker n'est volontairement **pas** monté. Même un proxy de socket
présenté comme lecture seule peut autoriser, via des endpoints GET, la lecture
de journaux ou de fichiers d'autres conteneurs. Netdata affiche donc les
ressources des workloads Docker via les cgroups, sans disposer de leur inventaire
ou de leurs données. Portainer reste l'inventaire et l'outil d'administration
des conteneurs.

## Politique de collecte

Le fichier `netdata.conf` est déclaré dans le Compose, pas édité dans le volume.
La collecte de base est à une seconde. Les objectifs de rétention sont 14 jours
en haute résolution, trois mois au niveau intermédiaire et un an au niveau
agrégé. Chaque niveau vise au maximum 1 GiB de données : la durée effective peut
être plus courte, et les tailles sont des limites souples, pas des quotas disque.
Les journaux Docker tournent sur trois fichiers de 10 Mo. La télémétrie anonyme
est désactivée ; cela ne désactive pas une connexion Netdata Cloud déjà configurée.
La configuration Discord et le provisionnement du secret sont décrits dans
`ALERTING.md`. Le changement d'alerting doit rester non déployé tant que ce
secret n'est pas créé sur l'hôte ; un commit de préparation ne vaut pas un test.

## Lecture du tableau de bord

Dans la vue du nœud `homelab`, utiliser les sections système (CPU, mémoire,
pression de ressources), stockage (espace libre, inodes, latence et débit),
réseau, processus, services systemd et conteneurs/cgroups. Contrôler aussi les
métriques de Netdata lui-même et sa rétention effective. La présence d'un
graphique ne prouve pas que son collecteur fournit encore des points récents.

Les ressources Docker sont collectées, mais les noms lisibles et l'état Docker
ne sont pas encore intégrés : les cgroups apparaissent sous leurs identifiants.
Ne pas confondre cette vue avec un inventaire complet du moteur Docker.
Ne pas monter le socket Docker pour résoudre seulement cet affichage.

L'écran de rattachement Cloud n'est pas un tableau de bord personnalisé validé.
Cette opération éventuelle doit être faite par le propriétaire du compte, sans
partager la clé de session avec un assistant ni la conserver dans Git.

## Données et restauration

Les volumes suivants conservent configuration et historique local :

- `netdata-config` ;
- `netdata-lib` ;
- `netdata-cache`.

Ils ne sont pas encore inclus dans une sauvegarde automatisée. Le stack est
suivi par Portainer depuis `apps/netdata/compose.yaml` : modifier Git, relire,
committer puis laisser GitOps redéployer. Ne jamais modifier son compose dans
l'éditeur Web de Portainer.
