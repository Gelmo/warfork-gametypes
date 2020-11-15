# warfork-gametypes
Custom Gametypes for Warfork

## Notable gametypes:
### Packaged:
- gt_ftag - Freeze Tag and Freeze Tag Arena
- gt_ffaa - Free For All Arena (FFA CA, no teams, no rounds)
- gt_aa - Ammo Arena (Best-of-3 Duel Arena, less starting ammo, ammo pickups, only 1 EB)
- gt_rbduel - Round-Based Duel (Duel, round ends and everything resets when a player dies, first to win 3 rounds is the winner)
- gt_thunder - Thunder Pack
  - Thunder (LG-only, infinite ammo, FFA style, players have 300 health)
  - Thunder DA (Duel arena with LG-only)
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
- FBomb (Fixed bomb until 2.2 is released)
- UBomb (Unholy Bomb Arena, FBomb with holy trinity loadout, inifinite ammo, and no self/team dmg)
- Ignore wipeout; this is an old version, upstream is called Exhaustion
- Ignore the hny/hoony modes currently; WIP and need significant work

# Todo:

## Clanless Arena

## Hoonymode:
- Use RBDuel as base, but need to add spawn selection and tennis-style scoring

## Ftag:
- Push frozen players? - Not possible in 2.1, maybe when ascgame is merged. "They’re non solid because people were teleporting into frozen ppl and getting stuck"
- Remove defrost hazard multiplier for arena? - Tested with FTAG_INVERSE_HAZARD_DEFROST_SCALE and FTAG_INVERSE_ATTACK_DEFROST_SCALE set to 1, but matches went on too long. Set back to 3
- Fix defrost status indicator
- Implement Awards
- Currently, when a player falls through a pit, they don't respawn until their team loses a point. In QL, falling in a pit/lava respawns you (discouraging you from hurting opponents near a pit). Or just make them respawn when either team wins a point?

Things that need to be tested more in Ftag Arena with many skilled players:
- Armor and Health pickups on map (currently disabled in Arena)
- Powerup pickups on map (currently disabled in Arena)
- Respawning everyone (including health/armor refresh) when a team earns a point, like in CA
- Last update added weap/ammo pickups, and weap/ammo drops on death, which resolved the low-ammo issue. If it ends up being better to respawn everyone each point, it may be suitable to revert this and remove weap/ammo pickups (but retain weap/ammo drops)
