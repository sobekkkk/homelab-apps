# Décisions de supervision — 2026-09-30

- Netdata observe les ressources ; Kuma reste la supervision de disponibilité.
- L'alerting externe est reporté à la demande du propriétaire. Les diagnostics
  et états de santé locaux de Netdata ne sont pas supprimés.
- La politique de rétention et la rotation des logs sont versionnées dans Git.
  Les données historiques restent dans les volumes existants.
- Pas de socket Docker, ni de proxy générique de ce socket. Des noms de
  conteneurs plus lisibles ne justifient pas l'accès aux données des workloads.
- Pas de rattachement automatique à Netdata Cloud : aucun identifiant de session
  n'est lu, copié ou conservé. La télémétrie anonyme est désactivée.
- Les capacités et montages actuels sont conservés dans ce patch pour éviter une
  régression non testable sans activation. Ils restent un point de durcissement
  ouvert, notamment la racine hôte, D-Bus et SYS_PTRACE avec PID hôte.

## État de validation

Vérifié via l'API HTTPS privée : présence des métriques CPU, RAM, processus,
services systemd et cgroups. Les conteneurs sont identifiés par hash.
L'accès SSH non interactif fonctionne ; sudo non interactif demande un mot de
passe. Cette modification est préparée, pas déclarée déployée ni validée en
production. Une activation et un retest sont nécessaires.

Références :
- https://learn.netdata.cloud/docs/netdata-agent/configuration/database
- https://github.com/netdata/netdata/blob/v2.11.1/packaging/docker/run.sh
