# warfork-gametypes
Custom Gametypes for Warfork

## Notable gametypes:
### Packaged:
- Freeze Tag and Freeze Tag Arena
- Free For All Arena (FFA CA, no teams, no rounds)
- Ammo Arena (Best-of-3 Duel Arena, less starting ammo, ammo pickups, only 1 EB)
- Round-Based Duel (Duel, round ends and everything resets when a player dies, first to win 3 rounds is the winner)
- Thunder Pack
  - Thunder (LG-only, infinite ammo, FFA style, players have 300 health)
  - Thunder DA (Duel arena with LG-only)
- FFA Pack
  - Unholy Arena (RL/LG/EB-only, infinite ammo, FFA style without self dmg)
  - Unholy FFA (RL/LG/EB-only, infinite ammo, FFA style with self dmg)
  - Rocket Arena (RL-only, infinite ammo, FFA style without self dmg)
  - Team FFA (TDM but you spawn w/ weapons)

### To be Packaged:
- FBomb (Fixed bomb until 2.2 is released)
- UBomb (Unholy Bomb Arena, FBomb with holy trinity loadout, inifinite ammo, and no self/team dmg)
- Instagib Pack
  - Instagib (works on servers without g/sv_instagib set to 1, so you can play it on the Normal Weapons tab)
  - Gunblade Instagib (projectile instagib, splash damage does NOT count)
  - Rocket Instagib (projectile instagib, splash damage does count)
  - Slide (rocket and grenade instagib (with splash damage) but CA style, typically played on slick maps)
  - SlideFFA (rocket and grenade instagib (with splash damage) but FFA style, typically played on slick maps)
- Ignore wipeout; this is an old version, upstream is called Exhaustion
- Ignore the hny/hoony modes currently; WIP and need significant work

# Todo:

## Clanless Arena

## Hoonymode:
- Use RBDuel as base, but need to add spawn selection and tennis-style scoring

## Ftag:
- Push frozen players? - Not possible in 2.1, maybe when ascgame is merged. "They’re non solid because people were teleporting into frozen ppl and getting stuck"
- Remove defrost hazard multiplier for arena? - Disabled in 0.9.4.1 for arena, testing
- Respawn both teams each round for arena?
- Show frozen teammates through wall
- Fix defrost status indicator
- Implement Awards
