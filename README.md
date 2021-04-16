# warfork-gametypes
Custom Gametypes for Warfork

## Notable gametypes:
### Packaged:
- gt_ftag - Classic Freeze Tag (`ft`) and Freeze Tag Clan Arena (`ftca`)
- gt_ffaa - Free For All Arena (FFA CA, no teams, no rounds)
- gt_aa - Ammo Arena (Best-of-3 Duel Arena, less starting ammo, ammo pickups, only 1 EB)
- gt_rbduel - Round-Based Duel (Duel, round ends and everything resets when a player dies, first to win 3 rounds is the winner)
- gt_thunder - Thunder Pack
  - Thunder (LG-only, infinite ammo, FFA style, players start with 250 health, player gains 2 health when dealing damage (max health is 400))
  - Thunder DA (Duel arena with LG-only, infinite ammo, players start with 250 health, player gains 2 health when dealing damage (max health is 400))
- gt_ffap - FFA Pack
  - Unholy Arena (RL/LG/EB-only, infinite ammo, FFA style without self dmg)
  - Unholy FFA (RL/LG/EB-only, infinite ammo, FFA style with self dmg)
  - Rocket Arena (RL-only, infinite ammo, FFA style without self dmg)
  - Team FFA (TDM but you spawn w/ weapons)
- gt_instap - Instagib Pack
  - Instagib (works on servers without g/sv_instagib set to 1, so you can play it on the Normal Weapons tab)
  - Gunblade Instagib (projectile instagib, splash damage does NOT count)
  - Rocket Instagib (projectile instagib, splash damage does count)
  - Slide (rocket and grenade instagib (with splash damage) but CA style, typically played on slick maps)
  - SlideFFA (rocket and grenade instagib (with splash damage) but FFA style, typically played on slick maps)

### Not Packaged:
- Bomb Clan Arena: Still WIP
- Retakes: Still WIP
- Ignore wipeout; this is an old version, upstream is called Exhaustion
- Ignore the hny/hoony modes currently; WIP and need significant work

# Todo:

## Clanless Arena

## Hoonymode:
- Use RBDuel as base, but need to add spawn selection and tennis-style scoring

## Ftag:
- Make frozen players slow down when sliding (fake friction)
- Implement Awards
- Add AI Goals for bot support
