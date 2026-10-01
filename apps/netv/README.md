# NetV GitOps

Statut : configuration préparée, activation et lecture réelle non validées.

Voir le [runbook infrastructure](https://github.com/sobekkkk/nixos-homelab-conf/blob/main/docs/NETV.md)
pour le schéma, la migration TAP, les protections réseau et le rollback.

Ordre impératif : infrastructure NixOS en mode test → stack NetV → Caddy →
Homepage → recette de coupure VPN et lecture → persistance NixOS.

Dans Portainer : `netv-gitops`, dépôt `homelab-apps`, référence
`refs/heads/main`, Compose `apps/netv/compose.yaml`. Aucun fichier
additionnel, aucun token IPTV dans une variable d'environnement ou dans Git.
Compte admin et abonnement sont saisis dans l'interface privée HTTPS.

URL Tailscale : `https://homelab.tail239aaa.ts.net:8446/`.
URL LAN : `https://netv.home.arpa/` (DNS local et confiance CA Caddy requis).
Pas de port publié par NetV, pas de Docker socket, pas de second profil Mullvad.

`always` force le traitement serveur ; la CSP interdit le mode direct navigateur.
L'image épinglée n'est pas une promesse de lecture GPU : valider VAAPI, codecs et
charge avec une chaîne réelle. Initializer sans réseau, runtime UID 10001,
rootfs en lecture seule, ressources bornées. `netv-state` contient des secrets.
Ne pas exposer le gateway Xtream 8100 dans cette première version.

Les logs applicatifs ne sont pas conservés car l'amont peut y écrire des URL
sensibles. Utiliser santé Docker et Netdata ; jamais de debug avec les sources
enregistrées. Les règles réseau sont déclarées dans NixOS, pas dans Portainer.
