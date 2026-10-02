# Films, séries IPTV et transcodage Jellyfin

Définition Compose publiée et redéployée via Portainer le 2026-10-02 depuis
`refs/heads/main` (commit de configuration `0dc13c9`). Jellyfin, Dispatcharr,
PostgreSQL et Redis sont healthy ; le worker est running et l'initialisation
est terminée avec code 0. VOD2MLIB 1.18.0 a ensuite été installé depuis le
catalogue Dispatcharr (signature vérifiée par l'interface), activé et configuré
avec le proxy interne, les NFO et le format de dossiers Jellyfin. Le scan VOD
du compte Xtream est activé ; les films apparaissent dans Dispatcharr.
Les actions de génération ont été lancées avec les limites 10 films / 1 série ;
Les bibliothèques Films IPTV et Séries IPTV sont créées : Jellyfin affiche
les 10 films de recette (avec affiches) et une série. Cela confirme la découverte
du catalogue partagé, pas encore la lecture des flux ni toutes les permissions.
Langue français, pays laissé vide ; fournisseurs de métadonnées et d'images
en ligne désactivés, sauvegarde NFO/images et extraction trickplay/chapitres
désactivées. Surveillance en temps réel activée. Le tableau de bord confirme
10 films, 1 série et 10 épisodes. Le 2026-10-02, l'opérateur a validé vainfo
dans le conteneur : Intel iHD, VA-API 1.24, ouverture renderD128 réussie.
Le profil VA-API a été enregistré dans Jellyfin : décodage H264, HEVC,
HEVC 10bit, MPEG2, VC1, VP8, VP9 et VP9 10bit ; encodage matériel H264.
AV1, HEVC RExt, sortie HEVC/AV1, modes basse consommation et tone mapping
restent désactivés. Cache explicite /cache/transcodes. Lecture et transcodage
réels restent à tester ; vainfo ne constitue pas une recette de lecture.
Aucun cron n'a été enregistré. Pas de coupure VPN.
Live TV reste inchangée. Le catalogue contient des liens, pas une copie des
vidéos : fournisseur et abonnement doivent rester disponibles.

## Contrat

```text
Catalogue Xtream -> Dispatcharr + VOD2MLIB -> volume media-vod-library
                                            | .strm et .nfo
                                            v lecture seule
Client -> Jellyfin -> dispatcharr-media:9191/proxy/vod/... -> VM -> Mullvad
          | si nécessaire
          v
       Intel VA-API /dev/dri/renderD128
```

Le volume est écrit par web/worker, lu seulement par Jellyfin. Initialisation
des trois répertoires : UID/GID 10003, mode 2770 ; umask 0027 demandé aux writers.
Jellyfin garde UID 10002, racine readonly, aucune capability, aucun mode
privileged ; groupes supplémentaires 10003 (catalogue) et 303 (render vérifié).
Seul le render node est exposé, pas card0, le socket Docker ou tout /dev/dri.
Le périphérique hôte était déjà en mode 0666 ; aucun chmod hôte n'est effectué.
Cela ajoute une surface d'attaque driver GPU, limitée au seul conteneur Jellyfin.

## Avant déploiement

Accord explicite requis pour publication/redéploiement de media-gitops et accès
GPU. Ne pas créer une seconde stack. Ne jamais supprimer les volumes existants.
Installer le plugin tiers seulement après accord, version 1.18.0 depuis le
catalogue Dispatcharr ; relire son code et conserver la version exacte utilisée.
La compatibilité déclarée commence à Dispatcharr 0.24.0, pas une preuve de recette
sur notre 0.31.0. Ne pas passer à une image dev pour contourner un bug.

## Import initial dans Dispatcharr

1. M3U & EPG Manager -> compte Xtream existant : Enable VOD Scanning, puis
   choisir une petite sélection de catégories Movies et Series et rafraîchir.
   Respecter Max Streams de l'abonnement ; pas de scans concurrents aux lectures.
2. Find Plugins -> VOD to Media Library, version revue, puis activer.
3. Dans ses settings : Movies `/VODS/Movies`, Series `/VODS/Series`, Dispatcharr
   URL **`http://dispatcharr-media:9191`**. N'utiliser ni URL fournisseur ni
   localhost ni URL Tailscale pour ces liens serveur à serveur.
4. Batch 10 films et 1 série, NFO activés, dossiers TMDB activés au format
   **Jellyfin/Emby `[tmdbid-123]`**, option de suppression stream_id désactivée.
5. Catalogue snapshot puis génération limitée. Vérifier côté opérateur les
   permissions et l'autorité des liens sans imprimer leur contenu/token.
   Si Jellyfin ne peut lire les fichiers, revoir les writers/umask ; pas chmod 777.
6. Tester un film et un épisode, avance rapide/reprise, puis rafraîchir le
   compte et vérifier que les liens restent lisibles. Des UUID de VOD peuvent
   changer avec certaines versions : régénération puis scan Jellyfin à tester.

## Bibliothèques Jellyfin

Créer Films IPTV (type Films) -> `/media/iptv-vod/Movies`, et Séries IPTV
(type Séries) -> `/media/iptv-vod/Series`. Langue français, pays choisi par le
propriétaire. Commencer avec NFO locaux ; désactiver avant le premier scan
les fournisseurs de métadonnées en ligne et les téléchargements d'images
automatiques pour éviter une collecte massive sur un catalogue entier.
Ajouter ensuite des posters/métadonnées de façon mesurée sur la sélection.
Ne pas activer sauvegarde des métadonnées dans ces dossiers readonly.
Désactiver extraction des miniatures vidéo, trickplay et analyses automatiques
chapitres/intros susceptibles d'ouvrir les flux fournisseur sans lecture demandée.

Après recette, planifier export et scan Jellyfin à des horaires distincts.
Refresh Existing Series + Full rescan permettent d'inclure les nouveaux épisodes.
La tâche planifiée utilise le worker Celery `dvr` : vérifier son exécution réelle
sur notre déploiement modular avant de promettre une synchronisation nocturne.

## Profil de lecture initial

Le serveur inspecté : i5-10300H, pilote i915, renderD128 GID 303, RAM 7737 MiB.
Préférer Direct Play/remux ; Dispatcharr ne réencode pas systématiquement.
Dans Jellyfin -> Lecture -> Transcodage, après preuve que vainfo fonctionne
dans le conteneur avec son UID réel :

- VA-API et `/dev/dri/renderD128` : choix de maintenance pour cette génération
  Intel, dont le runtime QSV historique est déprécié.
- Activer seulement les décodeurs rapportés par vainfo : commencer H.264 et
  HEVC/HEVC 10-bit si présents. AV1 matériel reste désactivé sur ce CPU.
- Encodage matériel activé ; sortie H.264 au premier test pour compatibilité.
  HEVC sera testé ensuite selon clients ; pas d'AV1 en sortie matérielle.
- Tone mapping désactivé initialement ; HDR->SDR testé séparément avant activation.
- Répertoire transcodage `/cache/transcodes`, pas /tmp borné à 256 MiB.
- Ne pas baisser arbitrairement le débit global : mesurer le trajet client,
  puis tester un transcodage 1080p modéré. Garder un seul transcodage au début.

Recette opérateur : `vainfo` fourni par jellyfin-ffmpeg dans le conteneur,
puis lecture courte avec baisse volontaire de qualité côté client. Confirmer
activité GPU, faible charge CPU et lecture stable. Ne pas publier de logs FFmpeg
bruts : ils peuvent contenir les URLs fournisseur. Les bibliothèques ont été
créées dans l'interface ; la définition Compose seule ne les crée pas.
L'accès au pilote et le profil enregistré sont validés ; le transcodage réel
n'est pas déclaré fonctionnel avant cette recette.

Sources :
- https://github.com/R3XCHRIS/VOD2MLIB/tree/v1.18.0
- https://dispatcharr.github.io/Dispatcharr-Docs/plugin-listing/
- https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/intel/
