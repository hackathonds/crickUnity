import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'sponsor_models.dart';
import 'sponsor_provider.dart';

/// DS §11.9: "Sponsor Console: marketplace list -> entity detail ->
/// [Make offer] form -> offer states (sent/countered/accepted)."
class SponsorConsoleScreen extends ConsumerWidget {
  const SponsorConsoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(sponsorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sponsor console'),
        actions: [
          IconButton(
            key: const ValueKey('campaignDashboardButton'),
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Campaign dashboard',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CampaignDashboardScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Marketplace',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final listing in state.listings)
            Card(
              key: ValueKey('marketplaceListingCard_${listing.entityName}'),
              child: ListTile(
                title: Text(listing.entityName),
                subtitle: Text(
                  '${sponsorEntityTypeLabels[listing.entityType]} -- '
                  '${listing.audienceStat} audience -- seeking '
                  '${listing.seekingAssets.map((a) => sponsorAssetLabels[a]).join(', ')}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _EntityDetailScreen(listing: listing),
                  ),
                ),
              ),
            ),
          if (state.offers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'My offers',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final offer in state.offers)
              _OfferCard(key: ValueKey('offerCard_${offer.id}'), offer: offer),
          ],
        ],
      ),
    );
  }
}

class _OfferCard extends ConsumerWidget {
  final SponsorOffer offer;

  const _OfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(sponsorProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${offer.entityName} -- ${sponsorAssetLabels[offer.asset]}',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          Text(
            '₹${offer.amountRupees} / ${offer.durationWeeks}w -- '
            '${offerStatusLabels[offer.status]}'
            '${offer.counterAmountRupees != null ? ' (countered ₹${offer.counterAmountRupees})' : ''}',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          if (offer.status == OfferStatus.countered)
            Row(
              children: [
                TextButton(
                  onPressed: () => notifier.declineOffer(offer.id),
                  child: const Text('Decline'),
                ),
                FilledButton(
                  key: ValueKey('acceptCounterButton_${offer.id}'),
                  onPressed: () => notifier.acceptOffer(offer.id),
                  child: const Text('Accept counter'),
                ),
              ],
            )
          else if (offer.status == OfferStatus.sent)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: ValueKey('simulateCounterButton_${offer.id}'),
                onPressed: () =>
                    notifier.receiveCounter(offer.id, offer.amountRupees + 500),
                child: const Text('(QA) Simulate counter'),
              ),
            ),
        ],
      ),
    );
  }
}

class _EntityDetailScreen extends StatelessWidget {
  final MarketplaceListing listing;

  const _EntityDetailScreen({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(listing.entityName)),
      body: _MakeOfferForm(listing: listing),
    );
  }
}

class _MakeOfferForm extends ConsumerStatefulWidget {
  final MarketplaceListing listing;

  const _MakeOfferForm({required this.listing});

  @override
  ConsumerState<_MakeOfferForm> createState() => _MakeOfferFormState();
}

class _MakeOfferFormState extends ConsumerState<_MakeOfferForm> {
  SponsorAsset? _asset;
  int _amount = 5000;
  int _durationWeeks = 4;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asset',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final asset in widget.listing.seekingAssets)
                ChoiceChip(
                  key: ValueKey('offerAssetChip_${asset.name}'),
                  label: Text(sponsorAssetLabels[asset]!),
                  selected: _asset == asset,
                  onSelected: (_) => setState(() => _asset = asset),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Amount: ₹$_amount',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          Slider(
            key: const ValueKey('offerAmountSlider'),
            value: _amount.toDouble(),
            min: 1000,
            max: 50000,
            divisions: 49,
            onChanged: (v) => setState(() => _amount = v.round()),
          ),
          Text(
            'Duration: $_durationWeeks weeks',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          Slider(
            key: const ValueKey('offerDurationSlider'),
            value: _durationWeeks.toDouble(),
            min: 1,
            max: 52,
            divisions: 51,
            onChanged: (v) => setState(() => _durationWeeks = v.round()),
          ),
          const Spacer(),
          FilledButton(
            key: const ValueKey('sendOfferButton'),
            onPressed: _asset == null
                ? null
                : () {
                    ref
                        .read(sponsorProvider.notifier)
                        .makeOffer(
                          entityName: widget.listing.entityName,
                          asset: _asset!,
                          amountRupees: _amount,
                          durationWeeks: _durationWeeks,
                        );
                    Navigator.of(context).pop();
                  },
            child: const Text('Send offer'),
          ),
        ],
      ),
    );
  }
}

class CampaignDashboardScreen extends ConsumerStatefulWidget {
  const CampaignDashboardScreen({super.key});

  @override
  ConsumerState<CampaignDashboardScreen> createState() =>
      _CampaignDashboardScreenState();
}

class _CampaignDashboardScreenState
    extends ConsumerState<CampaignDashboardScreen> {
  static const _periods = ['This month', 'This quarter'];
  int _periodIndex = 0;

  void _export(List<CampaignStat> stats) {
    final lines = [
      'Campaign dashboard (${_periods[_periodIndex]})',
      for (final stat in stats)
        '${sponsorAssetLabels[stat.asset]}: ${stat.impressions} impressions, '
            '${stat.engagement} engagement',
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Campaign card copied')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final stats = ref.watch(sponsorProvider).campaignStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign dashboard'),
        actions: [
          IconButton(
            key: const ValueKey('exportCampaignCardButton'),
            icon: const Icon(Icons.ios_share),
            onPressed: () => _export(stats),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < _periods.length; i++)
                ChoiceChip(
                  label: Text(_periods[i]),
                  selected: _periodIndex == i,
                  onSelected: (_) => setState(() => _periodIndex = i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final stat in stats)
            Row(
              key: ValueKey('campaignStatRow_${stat.asset.name}'),
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sponsorAssetLabels[stat.asset]!.toUpperCase(),
                          style: AppTypography.label.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                        Text(
                          '${stat.impressions}',
                          style: AppTypography.stat.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${stat.engagement} engagement',
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
