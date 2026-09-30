# Homelab applications

Ce dépôt privé est la source de vérité des applications Docker du homelab.
NixOS déclare l'hôte, Docker, le réseau et Portainer ; chaque dossier sous
`apps/` déclare une application déployée par Portainer depuis Git.

## Règles simples

- aucun secret, jeton, mot de passe, export ou donnée applicative dans Git ;
- une image est épinglée par tag **et** digest ;
- chaque application documente ses ports, volumes, sauvegarde et restauration ;
- les modifications passent par un commit relu puis par Portainer GitOps ;
- aucun service ne publie de port ou ne rejoint Internet par défaut.

## Applications présentes

- `uptime-kuma` : disponibilité des interfaces et services ;
- `netdata` : métriques temps réel de l'hôte, systemd et des workloads Docker.

Le guide complet de l'architecture est conservé dans le dépôt NixOS privé de
l'administration, `docs/GITOPS.md`.
