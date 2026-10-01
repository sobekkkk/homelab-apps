# Décisions applicatives

## 2026-10-01 — Homepage

- Portail de liens, pas un nouvel outil d'administration ou de monitoring.
- Réutiliser Caddy ; réserver 8445 au relais privé Homepage, sans changer les
  listeners existants. Aucun port routeur, WAN ou Funnel.
- Démarrer sans widgets à secrets ni socket Docker. Ne pas afficher de métriques
  du conteneur comme s'il s'agissait de métriques de l'hôte.
- Configurations inline pour éviter les bind relatifs absents dans Portainer.
  Utilisateur non-root, cache éphémère et limites explicites.
- Authentification applicative non activée dans la proposition initiale : LAN
  de confiance et tailnet sont la frontière d'accès, pas allowed-hosts. À revoir
  avant activation si le LAN n'est pas de confiance.
- Publication sur branche de revue : aucun redéploiement automatique de main
  avant autorisation explicite de l'opérateur.

## 2026-10-01 — Compatibilité configs.content / Portainer CE

L'opérateur a autorisé l'activation puis observé le refus de déploiement des
configs inline dans un service readonly. Conserver les configs inline évite
les bind relatifs non accessibles depuis le daemon. Retirer readonly uniquement
pour Homepage, sans privilège ou montage hôte supplémentaire, et déclarer les
configs avec mode 0444. La couche du conteneur peut donc être modifiée par son
UID ; ce compromis n'est pas présenté comme un durcissement équivalent.
Non-root, cap_drop ALL, no-new-privileges, limites et absence de socket restent.
Validation statique avant publication ; déploiement et modes effectifs à retester
dans Portainer. Aucun changement NixOS ou pare-feu requis pour cette correction.
