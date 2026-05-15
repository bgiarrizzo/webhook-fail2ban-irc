# FEATURES

## Supported webhook sources
- bazarr -> #seedbox
- radarr -> #seedbox
- sonarr -> #seedbox
- lidarr -> #seedbox
- prowlarr -> #seedbox
- fail2ban -> #sysops

## Pre-configured channel routes (for future handlers)
- github -> #git
- gitlab -> #git
- forgejo -> #git
- gitea -> #git

## Normalized summaries
- Bazarr: [Bazarr] {message} (error|warning|info|success)
- Radarr: summaries vary by eventType (movieadded, grab, download, rename, health, update, ...)
- Sonarr: summaries vary by eventType (download, grab, episodeadded, episodeimported, rename, ...)
- Lidarr: summaries vary by eventType (albumadded, download, grab, health, retag, ...)
- Prowlarr: summaries vary by eventType (grab, health, indexer events, update, ...)
- Fail2ban: [Fail2ban] IP bannie : {ip} (jail: {jail})

## Security behavior
- Source token validation via X-Webhook-Token.
- Source unknown returns 404.
- Missing or invalid token returns 401.
- Invalid JSON payload returns 400.

## Message safety
- IRC messages are sanitized to remove CR/LF and control characters.
- Message length is capped to 400 characters.
