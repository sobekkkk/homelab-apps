# Média privé : Dispatcharr + Jellyfin

**Préparation uniquement : pas encore déployé ni validé en lecture.**
Migration parallèle à NetV, sans reprise automatique en clair. Voir le contrat
réseau et le rollback dans `docs/MEDIA_MIGRATION.md` du dépôt infra.

## Portainer

Après activation infra approuvée : stack `media-gitops`, dépôt `homelab-apps`,
référence de migration approuvée, chemin `apps/media/compose.yaml`.
Ne pas changer les IPs, raccorder un bridge WAN ou publier 8096/9191 pour
« réparer » la connexion. Mettre Caddy à la même révision **après** création du
réseau media-ingress. Aucun secret ni variable obligatoire à saisir dans
Portainer : les secrets DB/cache sont générés dans le volume runtime.

| Interface | Tailscale | LAN |
| --- | --- | --- |
| Jellyfin | https://homelab.tail239aaa.ts.net:8447 | https://jellyfin.home.arpa:8447 |
| Dispatcharr | https://homelab.tail239aaa.ts.net:8448 | https://dispatcharr.home.arpa:8448 |

Les noms LAN nécessitent une résolution locale vers 192.168.1.69 et la CA Caddy
de confiance. Ne pas désactiver TLS dans les clients pour cacher un problème de
certificat. Les interfaces Tailscale utilisent le certificat du tailnet.

## Mise en service

1. Créer un compte admin Dispatcharr avec un mot de passe unique. Les saisies
   fournisseur restent dans cette interface privée : ne rien transmettre à
   l'agent ni dans Git. Importer d'abord **une petite sélection de chaînes**,
   sa source M3U ou Xtream et son guide EPG. Respecter la limite de connexions.
2. Choisir une sortie **proxy/relay**, jamais un profil de redirection vers le
   fournisseur. Commencer sans réencodage : passthrough/remux, buffers par
   défaut. Tester une chaîne directement dans Dispatcharr avant Jellyfin.
3. Dans la section Connect de Dispatcharr, relever ses endpoints de sortie
   M3U et XMLTV. Conserver chemins et éventuels tokens dans les réglages
   Jellyfin uniquement. Remplacer leur autorité publique par
   `http://dispatcharr-media:9191`, sans modifier le reste de l'URL. Cet alias
   existe seulement sur l'ingress interne, pas sur le bridge VPN commun.
4. Créer l'admin Jellyfin, refuser le port mapping automatique, puis créer un
   utilisateur de lecture non administrateur. Dans **Tableau de bord → TV en
   direct**, ajouter un tuner M3U et la source XMLTV interne. Ne pas coller le
   M3U original du fournisseur dans Jellyfin : il doit consommer le relais.
5. Vérifier les URLs de chaînes générées : elles doivent rester sur
   Dispatcharr interne, pas son URL publique ni celle du fournisseur. Choisir
   dans Dispatcharr son adresse de sortie interne si le réglage est disponible.
   Si ce réglage manque, arrêter la recette et inspecter le format d'export
   sans afficher les tokens ; ne pas ouvrir le pare-feu vers le LAN.
6. Configurer l'application Jellyfin Windows/web, Android et Android TV avec
   `https://homelab.tail239aaa.ts.net:8447`. La TV doit rejoindre le même
   tailnet. Pas d'exit node nécessaire pour le flux fournisseur relayé ici.
7. Faire un essai stable de 10 minutes, vérifier le mode Direct Play/remux et
   les métriques CPU/RAM. Valider ensuite Android TV et le changement de chaîne.
   Si des codecs demandent un réencodage, activer ensuite QSV/VAAPI après revue
   du GPU ; ne pas forcer le transcodage pour toutes les chaînes.

Le Live TV et XMLTV sont l'intégration initiale. La VOD/replay dépend du
fournisseur et **ne devient pas automatiquement une bibliothèque Jellyfin**.
Configurer un export adapté dans une seconde étape, avec sa propre recette.
Le DVR Jellyfin utilisera `/recordings` après choix de quotas/rétention ; les
enregistrements du DVR Dispatcharr sont séparés, ne pas activer les deux en
même temps pour le même programme.

## Validation propriétaire

Après déploiement, les contrôles privilégiés restent opérés par le propriétaire.
Ne pas afficher `docker inspect` complet, environnements, arguments Redis,
fichiers de paramètres, M3U ou logs bruts : ils peuvent révéler des secrets.

- `docker compose config --quiet` valide la définition, pas la connectivité.
- Conteneurs healthy : DB/Redis/web/Jellyfin ; tâche EPG réussie pour le worker.
- Valider une sortie Mullvad depuis web, worker et Jellyfin. Pour Jellyfin,
  `curl` est disponible ; pour Dispatcharr, utiliser Python. Ne retourner que
  l'IP de sortie et le booléen Mullvad, pas des credentials.
- Demander l'approbation avant toute coupure VPN/restart pour la recette de
  fail-closed. Arrêter les lectures pendant le test.
- Ajouter ensuite sondes privées `/health` Jellyfin et page web Dispatcharr à
  Kuma, plus présence worker/DB/Redis et pression mémoire dans Netdata.
  Une sonde HTTP verte ne prouve pas qu'un flux fournisseur fonctionne.

Les images et digests sont vérifiés le 2026-10-02. Des volumes nommés conservent
comptes, secrets, PostgreSQL et enregistrements ; ne jamais les effacer lors
d'un rollback. Les autres travaux Netdata restent sur leur branche dédiée.
