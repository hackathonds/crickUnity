/// Every icon named in DS §2.5, grouped by family in the same order the
/// spec lists them. `coin` is the reserved multicolor exception — see
/// [AppIconGlyph.isMulticolor].
enum AppIconId {
  // Navigation
  home,
  matches,
  plus,
  people,
  avatar,

  // Sports
  bat,
  ball,
  stumps,
  gloves,
  helmet,
  whistle,
  scorebook,
  trophy,
  pitch,

  // Status
  live,
  verifiedCheck,
  pendingClock,
  locked,
  syncedOfflineCloud,

  // Trust & Sportsmanship (DS §11.5 Addendum -- not in the base §2.5
  // set, but required by the Trust/Sportsmanship band chip)
  shield,

  // Rewards
  coin,
  xpBolt,
  chest,
  spin,
  scratch,

  // Expense
  receipt,
  split,
  settleHandshake,
  wallet,
  remindBell,

  // Social
  heart,
  props,
  comment,
  shareArc,
  bookmark,

  // Utility — generic chrome symbols DS §2.5's families don't cover
  // (search bar, dialogs, navigation back). Hand-drawn in the same
  // rounded-outline style as the rest of this set rather than falling
  // back to Material icons, per DS §2.5: "never mix stroke weights."
  search,
  mic,
  qrCode,
  close,
  backArrow,
}
