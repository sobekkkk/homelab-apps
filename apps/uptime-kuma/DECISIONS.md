# Décisions — sortie réseau Kuma — 2026-09-30

## Besoin et constat

Le propriétaire autorise explicitement la correction réseau et le push GitOps.
Le test Discord échoue avec `getaddrinfo ENOTFOUND discord.com`. Le Compose
connecte Kuma uniquement à un réseau `internal: true`, sans sortie externe.
Cette configuration explique très probablement le défaut ; la validation
runtime et la réception du message restent à effectuer après déploiement.

## Choix retenu

- Conserver le réseau interne Kuma/Caddy.
- Ajouter uniquement à Kuma un bridge de sortie dédié, géré par Compose.
- Ne pas rattacher Kuma au réseau proxy partagé, publier de port ou donner de
  privilèges supplémentaires. Conserver images et volumes actuels.
- Ne pas imposer un DNS public : utiliser la résolution Docker/hôte existante.
- Ne pas filtrer Discord par IP : ses adresses peuvent changer. Ne pas ajouter
  de proxy de sortie pour ce seul webhook sans besoin de cloisonnement plus fort.
- Accepter explicitement une sortie non limitée à Discord. Cette exception
  augmente la surface accessible depuis Kuma en cas de compromission ; ce n'est
  pas une politique de sortie strictement limitée au DNS et à HTTPS.
- Conserver le secret webhook dans Kuma, jamais dans les fichiers versionnés.
- Différer le paramétrage Discord de Netdata : ce patch ne concerne que le
  rétablissement des notifications Kuma déjà configurées.

## Validation

La validation Compose est exécutée avant le push. La validation de bout en bout
nécessite un conteneur redéployé et un test reçu dans Discord ; un push réussi
ne suffit pas à qualifier la correction de vérifiée.

Référence : https://docs.docker.com/reference/compose-file/networks/#internal
