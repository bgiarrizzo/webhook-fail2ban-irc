# APP

## Objective
webhook-irc-relay receives HTTP webhooks from external systems, normalizes them, and relays formatted messages to IRC channels.

## Primary use cases
- Notify seedbox activity from Radarr, Sonarr, Lidarr, and Prowlarr.
- Notify security events from Fail2ban.
- Route each source to a dedicated IRC channel.

## Non-goals
- No database or Fluent persistence.
- No external queue broker in v1.
- No third-party IRC library.

## Inputs and outputs
- Input: POST /webhooks/:source with JSON body.
- Output: IRC PRIVMSG sent to the mapped channel.

## Extensibility model
Adding a new source requires only:
1. A new handler file in Infrastructure/Handlers.
2. One registration line in App/configure.swift.
3. One source-to-channel mapping in Application/IRCChannelRouter wiring.
