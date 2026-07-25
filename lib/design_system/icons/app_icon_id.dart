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
}
