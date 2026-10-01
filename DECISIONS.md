# Décisions applicatives

## 2026-10-01 — Homepage

- Portail de liens, pas un nouvel outil d'administration ou de monitoring.
- Réutiliser Caddy ; réserver 8445 au relais privé Homepage, sans changer les
  listeners existants. Aucun port routeur, WAN ou Funnel.
- Démarrer sans widgets à secrets ni socket Docker. Ne pas afficher de métriques
  du conteneur comme s'il s'agissait de métriques de l'hôte.
- Configurations inline pour éviter les bind relatifs absents dans Portainer.
  Racine readonly, utilisateur non-root, cache éphémère et limites explicites.
- Authentification applicative non activée dans la proposition initiale : LAN
  de confiance et tailnet sont la frontière d'accès, pas allowed-hosts. À revoir
  avant activation si le LAN n'est pas de confiance.
- Publication sur branche de revue : aucun redéploiement automatique de main
  avant autorisation explicite de l'opérateur.
