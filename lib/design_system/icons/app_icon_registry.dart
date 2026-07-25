import 'app_icon_glyph.dart';
import 'app_icon_glyphs_expense.dart';
import 'app_icon_glyphs_navigation.dart';
import 'app_icon_glyphs_rewards.dart';
import 'app_icon_glyphs_social.dart';
import 'app_icon_glyphs_sports.dart';
import 'app_icon_glyphs_status.dart';
import 'app_icon_id.dart';

/// Every icon glyph, keyed by [AppIconId] — the single source the [AppIcon]
/// widget and the icon-gallery debug screen both read from.
final Map<AppIconId, AppIconGlyph> appIconGlyphs = {
  ...navigationIconGlyphs,
  ...sportsIconGlyphs,
  ...statusIconGlyphs,
  ...rewardsIconGlyphs,
  ...expenseIconGlyphs,
  ...socialIconGlyphs,
};

/// Family groupings, in DS §2.5's order — used by the icon-gallery screen.
final Map<String, List<AppIconId>> appIconFamilies = {
  'Navigation': [
    AppIconId.home,
    AppIconId.matches,
    AppIconId.plus,
    AppIconId.people,
    AppIconId.avatar,
  ],
  'Sports': [
    AppIconId.bat,
    AppIconId.ball,
    AppIconId.stumps,
    AppIconId.gloves,
    AppIconId.helmet,
    AppIconId.whistle,
    AppIconId.scorebook,
    AppIconId.trophy,
    AppIconId.pitch,
  ],
  'Status': [
    AppIconId.live,
    AppIconId.verifiedCheck,
    AppIconId.pendingClock,
    AppIconId.locked,
    AppIconId.syncedOfflineCloud,
  ],
  'Rewards': [
    AppIconId.coin,
    AppIconId.xpBolt,
    AppIconId.chest,
    AppIconId.spin,
    AppIconId.scratch,
  ],
  'Expense': [
    AppIconId.receipt,
    AppIconId.split,
    AppIconId.settleHandshake,
    AppIconId.wallet,
    AppIconId.remindBell,
  ],
  'Social': [
    AppIconId.heart,
    AppIconId.props,
    AppIconId.comment,
    AppIconId.shareArc,
    AppIconId.bookmark,
  ],
};
