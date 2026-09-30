# Décisions de supervision — 2026-09-30

- Netdata observe les ressources ; Kuma reste la supervision de disponibilité.
- L'alerting a d'abord été reporté, puis demandé explicitement. Les alertes
  natives de Netdata sont conservées ; Discord sera envoyé par l'agent local.
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

## Préparation Discord

Le webhook partagé dans la conversation n'est pas utilisé ni reproduit. Son
propriétaire doit le révoquer et provisionner un remplaçant sur le serveur.
La configuration non sensible est préparée dans Git ; le secret est un fichier
root local, monté en lecture seule, sans ajout de port ni privilège. Ce patch
n'est pas poussé avant création du fichier pour éviter de casser GitOps.
Une réception réelle dans Discord sera nécessaire pour valider l'activation.

## Jeu ciblé demandé après le test Discord

Le propriétaire a montré la réception des tests WARNING, CRITICAL et CLEAR.
La chaîne Discord de l'agent est donc testée. La personnalisation prépare
17 règles sur des graphiques existants et conserve OOM/corruption mémoire.
La liste fermée supprime les doublons natifs et les règles non retenues ; il
faut réévaluer explicitement la couverture à chaque nouvelle intégration.
Les valeurs instantanées observées servent de baseline, pas de preuve de SLO.
Hystérésis, moyennes, délais et rappels critiques limitent le bruit.
Aucun accès supplémentaire, secret lu ou incident artificiel n'est nécessaire.
Le déploiement du nouveau jeu et le retest runtime restent soumis à approbation.

## Correction du déploiement Portainer (2026-09-30)

L'activation approuvée a échoué : `configs.file` produisait un bind vers
`/data/compose/4/...`, chemin interne au conteneur Portainer et absent de
l'hôte Docker. C'était une erreur du patch, pas un secret manquant.
Les règles non sensibles sont désormais intégrées via `configs.content`,
comme les autres configurations de la stack. Aucun volume, port, privilège
ou secret n'est changé. Les dollars sont échappés pour Compose ; le test
offline vérifie leur échappement et la parité avec le fichier canonique.
Le retest de chargement/évaluation nécessite encore le redéploiement depuis
Git ; la validation statique ne constitue pas une validation runtime.

Références :
- https://docs.docker.com/reference/compose-file/configs/
- https://docs.docker.com/reference/compose-file/interpolation/
- https://learn.netdata.cloud/docs/netdata-agent/configuration/database
- https://github.com/netdata/netdata/blob/v2.11.1/packaging/docker/run.sh
