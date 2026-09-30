# Notifications Discord de l'agent

Les règles ciblées sont versionnées dans `health.d/homelab.conf`, monté via
`configs.file` pour éviter l'interpolation des variables `$this` par Compose.
La liste autorisée est `homelab_* oom_kill 1hour_memory_hw_corrupted` : les
autres règles natives ne sont plus chargées après activation. Toute nouvelle
intégration doit donc faire l'objet d'une revue de couverture. Kuma reste
responsable de la disponibilité HTTP ;
Netdata observe les ressources et la santé système. Le webhook Netdata devrait
être distinct de celui de Kuma pour permettre une révocation indépendante.

Le Compose versionne la configuration non sensible. L'URL reste dans un fichier
administré sur l'hôte, monté en lecture seule. Aucun rattachement Cloud n'est
nécessaire pour les notifications de l'agent.

## Politique retenue

| Signal | Avertissement | Critique | Observation / notification |
| --- | --- | --- | --- |
| CPU occupé | >90 % | >98 % | Moyenne 10 min, notification après 2 min supplémentaires |
| RAM disponible | <10 % | <5 % | MemAvailable, notification après 5 min |
| Racine | >85 % utilisé ou <15 GiB libres | >95 % ou <5 GiB libres | Notification après 2 min |
| EFI `/boot` | <200 MiB libres | <100 MiB libres | Notification après 2 min |
| Inodes racine | <15 % libres | <5 % libres | Notification après 2 min |
| Pression mémoire PSI full | >5 % | >20 % | Moyenne noyau 5 min (full 300), notification après 2 min |
| Pression IO PSI full | >20 % | >50 % | Même fenêtre que la pression mémoire |
| Services essentiels | — | Non actifs pendant la fenêtre 2 min | Puis délai de notification 30 s |
| OOM / corruption mémoire | Règles natives épinglées avec l'image | Selon règles natives | Réglages natifs, pas de test destructif |

Les services ciblés sont Docker, tailscaled, sshd, auditd, nftables,
docker-lan-guard, docker-portainer et les trois relais Tailscale. Les unités
oneshot transitoires ne sont pas surveillées comme des démons permanents.

Les seuils de retour sont distincts des seuils de déclenchement (hystérésis).
Les retours à la normale sont notifiés après 2 minutes pour les services et
5 minutes pour les ressources. Pour les règles homelab : aucun rappel des
avertissements, rappel des critiques toutes les 4 heures. `delay` retarde les
notifications, pas l'état affiché ; les fenêtres `lookup` concernent l'évaluation.
Un maximum de `active` sur 2 minutes exige une absence continue dans les points
observés ; une collecte absente n'est pas une preuve de service arrêté.

Ces seuils sont un point de départ adapté à un lab de 8 CPU logiques et environ
233 GiB de racine, pas un SLO démontré par des semaines d'historique. Un build
Nix très long peut déclencher la règle CPU ; consulter les processus avant
d'interpréter cela comme une panne. Les notifications comprennent une première
consigne de diagnostic. Aucune suppression, réparation ou relance automatique
n'est prévue.

### Limites de couverture

Les noms et redémarrages individuels Docker ne sont pas fiables avec les seuls
cgroups par hash : aucune fausse alerte de restart n'est ajoutée. Kuma vérifie
les points HTTP. SMART/NVMe, températures, expiration TLS, sauvegardes et absence
de collecte ne sont pas couverts par ce jeu sans collecteurs ou sondes dédiés.
Un serveur ou Netdata arrêté ne peut pas envoyer sa propre alerte ; prévoir une
sonde indépendante. Les alertes systemd disparaissent si leur graphique n'est
plus collecté : vérifier la couverture, pas seulement l'absence de rouge.

## Revue du 30 septembre 2026

API : 241 entités natives, 155 CLEAR, 54 UNDEFINED et 32 UNINITIALIZED, aucune
WARNING/CRITICAL au moment de la revue. Cela ne signifie pas 86 pannes : des
variables et règles sans données pertinentes sont incluses. CPU moyen natif
environ 1,5 %, RAM disponible environ 80,6 %, racine 8 % utilisée et EFI 6 %.
Les graphiques et dimensions des 17 règles préparées ont été vérifiés.

Le Compose et les références sont contrôlés localement. La syntaxe définitive
et l'état CLEAR/évalué doivent être confirmés par Netdata après déploiement.
Ne pas qualifier le jeu de validé sur la seule base d'un lint Compose.

## Provisionnement unique, avant déploiement

Révoquer tout webhook partagé dans une conversation et en créer un nouveau
associé à un salon texte privé. Sur le serveur, créer le répertoire avec :

```sh
sudo install -d -m 0700 -o root -g root /var/lib/homelab-secrets
sudoedit /var/lib/homelab-secrets/netdata-discord.conf
```

Saisir dans l'éditeur, et non dans une commande ou dans Git :

```sh
DISCORD_WEBHOOK_URL="COLLER_ICI_LE_NOUVEAU_WEBHOOK"
```

Puis appliquer les permissions :

```sh
sudo chown root:root /var/lib/homelab-secrets/netdata-discord.conf
sudo chmod 0644 /var/lib/homelab-secrets/netdata-discord.conf
```

Le répertoire root 0700 empêche les comptes ordinaires de traverser le chemin.
Le fichier 0644 permet à l'utilisateur de service dans le conteneur de le lire
au point de montage. Root et les administrateurs Docker peuvent accéder au
secret ; ne pas leur attribuer une garantie d'isolation inexistante. Le fichier
est un fragment shell de confiance : seul root doit pouvoir le modifier.

Le nom de destinataire par défaut est `homelab-alertes`. Si le salon porte un
autre nom, ajouter `DEFAULT_RECIPIENT_DISCORD="nom-du-salon"` dans ce fichier.
Ne jamais sauvegarder un secret en clair dans le dépôt ni partager son contenu.

## Activation et test

Ne pousser ce changement qu'après le provisionnement du fichier : son absence
fait échouer le déploiement volontairement. Faire ensuite redéployer Netdata par
Portainer GitOps et vérifier la réception d'un test envoyé par le script officiel
`alarm-notify.sh test`, exécuté comme utilisateur `netdata` dans le conteneur.
Ne pas activer `NETDATA_ALARM_NOTIFY_DEBUG` ou partager la sortie brute : elle
peut contenir des informations sensibles. Vérifier séparément que les sondes
Kuma restent vertes.

L'activation n'est pas validée tant que le message n'est pas reçu. La réception
d'un test ne valide pas tous les seuils ; leur bruit et leur pertinence doivent
être observés avant personnalisation. Aucun incident artificiel ni saturation
du serveur ne doit être provoqué pour tester une notification.

Les notifications sortent par le réseau existant de Netdata. Aucune ouverture
de port entrant, exception TLS ou publication Internet n'est ajoutée.

## Restauration et rotation

Recréer le secret sur une machine de remplacement avant le déploiement GitOps.
Faire sa sauvegarde uniquement dans un mécanisme chiffré et restreint. Pour une
rotation, éditer le fichier root, redéployer le conteneur (un bind de fichier
peut garder l'ancien inode) puis tester. Révoquer l'ancien webhook dans Discord.

Référence : https://learn.netdata.cloud/docs/alerts-%26-notifications/notifications/agent-dispatched-notifications/discord
