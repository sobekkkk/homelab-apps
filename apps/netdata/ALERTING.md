# Notifications Discord de l'agent

Les alertes natives Netdata restent la base : avertissements, états critiques et
retours à la normale. Aucun seuil arbitraire supplémentaire n'est introduit sans
observer la charge réelle. Kuma reste responsable de la disponibilité HTTP ;
Netdata observe les ressources et la santé système. Le webhook Netdata devrait
être distinct de celui de Kuma pour permettre une révocation indépendante.

Le Compose versionne la configuration non sensible. L'URL reste dans un fichier
administré sur l'hôte, monté en lecture seule. Aucun rattachement Cloud n'est
nécessaire pour les notifications de l'agent.

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
