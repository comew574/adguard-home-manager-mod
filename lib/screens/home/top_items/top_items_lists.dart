import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adguard_home_manager/l10n/app_localizations.dart';

import 'package:adguard_home_manager/screens/home/top_items/top_items_screen.dart';
import 'package:adguard_home_manager/providers/clients_provider.dart';
import 'package:adguard_home_manager/functions/number_format.dart';
import 'package:adguard_home_manager/functions/snackbar.dart';
import 'package:adguard_home_manager/classes/process_modal.dart';
import 'package:adguard_home_manager/models/applied_filters.dart';
import 'package:adguard_home_manager/providers/app_config_provider.dart';
import 'package:adguard_home_manager/providers/logs_provider.dart';
import 'package:adguard_home_manager/functions/copy_clipboard.dart';
import 'package:adguard_home_manager/models/menu_option.dart';
import 'package:adguard_home_manager/providers/status_provider.dart';
import 'package:adguard_home_manager/constants/enums.dart';
import 'package:adguard_home_manager/screens/home/top_items/row_item.dart';

class TopItemsLists extends StatelessWidget {
  final List<HomeTopItems> order;

  const TopItemsLists({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final statusProvider = Provider.of<StatusProvider>(context);
    final appConfigProvider = Provider.of<AppConfigProvider>(context);
    final logsProvider = Provider.of<LogsProvider>(context);
    final clientsProvider = Provider.of<ClientsProvider>(context);

    void filterDomainLogs({required String value}) {
      logsProvider.setSearchText(value);
      logsProvider.setSelectedClients(null);
      logsProvider.setAppliedFilters(
        AppliedFiters(selectedResultStatus: 'all', searchText: value, clients: []),
      );
      appConfigProvider.setSelectedScreen(2);
    }

    void filterClientLogs({required String value}) {
      logsProvider.setSearchText(null);
      logsProvider.setSelectedClients([value]);
      logsProvider.setAppliedFilters(
        AppliedFiters(selectedResultStatus: 'all', searchText: null, clients: [value]),
      );
      appConfigProvider.setSelectedScreen(2);
    }

    void blockUnblock({required String domain, required String newStatus}) async {
      final ProcessModal processModal = ProcessModal();
      processModal.open(AppLocalizations.of(context)!.savingUserFilters);

      final rules = await statusProvider.blockUnblockDomain(domain: domain, newStatus: newStatus);

      processModal.close();

      if (!context.mounted) return;
      if (rules == true) {
        showSnackbar(appConfigProvider: appConfigProvider, label: AppLocalizations.of(context)!.userFilteringRulesUpdated, color: Colors.green);
      } else {
        showSnackbar(appConfigProvider: appConfigProvider, label: AppLocalizations.of(context)!.userFilteringRulesNotUpdated, color: Colors.red);
      }
    }

    void copyValueClipboard(dynamic value) {
      copyToClipboard(value: value, successMessage: AppLocalizations.of(context)!.copiedClipboard);
    }

    void blockUnblockClient(dynamic client) async {
      final currentList = clientsProvider.checkClientList(client);
      final newList = currentList == AccessSettingsList.allowed || currentList == null
          ? AccessSettingsList.disallowed
          : AccessSettingsList.allowed;

      ProcessModal processModal = ProcessModal();
      processModal.open(currentList == AccessSettingsList.allowed || currentList == null
          ? AppLocalizations.of(context)!.blockingClient
          : AppLocalizations.of(context)!.unblockingClient);

      final result = await clientsProvider.addClientList(client, newList);
      if (!context.mounted) return;

      processModal.close();

      if (result.successful == true) {
        showSnackbar(appConfigProvider: appConfigProvider, label: AppLocalizations.of(context)!.clientAddedSuccessfully, color: Colors.green);
      } else if (result.successful == false && result.content == 'client_another_list') {
        showSnackbar(appConfigProvider: appConfigProvider, label: AppLocalizations.of(context)!.clientAnotherList, color: Colors.red);
      } else {
        showSnackbar(appConfigProvider: appConfigProvider, label: newList == AccessSettingsList.allowed || newList == AccessSettingsList.disallowed
            ? AppLocalizations.of(context)!.clientNotRemoved
            : AppLocalizations.of(context)!.domainNotAdded, color: Colors.red);
      }
    }

    Widget buildCompactCard({
      required String label,
      required Color color,
      required List<Map<String, dynamic>> data,
      required String Function(dynamic) buildValue,
      required List<MenuOption> Function(dynamic) menuOptions,
      void Function(dynamic)? onTapEntry,
      bool isClient = false,
    }) {
      final displayData = data.length > 3 ? data.sublist(0, 3) : data;
      final showMore = data.length > 3;
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            ...displayData.asMap().entries.map((e) => _MiniRow(
              label: e.value.keys.first,
              value: buildValue(e.value.values.first),
              color: color,
              isLast: e.key == displayData.length - 1 && !showMore,
            )),
            if (showMore)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showFullList(context, label: label, data: data, buildValue: buildValue, menuOptions: menuOptions, onTapEntry: onTapEntry, width: MediaQuery.of(context).size.width, isClient: isClient),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('更多', style: TextStyle(fontSize: 11, color: color)),
                    Icon(Icons.chevron_right, size: 14, color: color),
                  ]),
                ),
              ),
          ],
        ),
      );
    }

    void _showFullList(BuildContext context, {required String label, required List<Map<String, dynamic>> data, required String Function(dynamic) buildValue, required List<MenuOption> Function(dynamic) menuOptions, void Function(dynamic)? onTapEntry, required double width, bool isClient = false}) {
      if (width > 700) {
        showDialog(context: context, builder: (ctx) => TopItemsScreen(
          type: isClient ? HomeTopItems.recurrentClients : HomeTopItems.queriedDomains,
          title: label, isClient: isClient, data: data, withProgressBar: true,
          buildValue: buildValue, options: (_) => menuOptions(_), onTapEntry: onTapEntry,
          isFullscreen: false,
        ));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => TopItemsScreen(
          type: isClient ? HomeTopItems.recurrentClients : HomeTopItems.queriedDomains,
          title: label, isClient: isClient, data: data, withProgressBar: true,
          buildValue: buildValue, options: (_) => menuOptions(_), onTapEntry: onTapEntry,
          isFullscreen: true,
        )));
      }
    }

    // Build card data for each section
    List<Map<String, dynamic>> cardData = [];
    for (final item in order) {
      switch (item) {
        case HomeTopItems.queriedDomains:
          cardData.add({
            'type': item,
            'label': AppLocalizations.of(context)!.topQueriedDomains,
            'color': Colors.blue,
            'data': statusProvider.serverStatus?.stats.topQueriedDomains ?? [],
            'buildValue': (v) => v.toString(),
            'menuOptions': (v) => [
              MenuOption(title: AppLocalizations.of(context)!.blockDomain, icon: Icons.block_rounded, action: () => blockUnblock(domain: v.toString(), newStatus: 'block')),
              MenuOption(title: AppLocalizations.of(context)!.copyClipboard, icon: Icons.copy_rounded, action: () => copyValueClipboard(v)),
            ],
            'onTapEntry': (v) => filterDomainLogs(value: v.toString()),
            'isClient': false,
          } as Map<String, dynamic>);
          break;
        case HomeTopItems.blockedDomains:
          cardData.add({
            'type': item,
            'label': AppLocalizations.of(context)!.topBlockedDomains,
            'color': Colors.red,
            'data': statusProvider.serverStatus?.stats.topBlockedDomains ?? [],
            'buildValue': (v) => v.toString(),
            'menuOptions': (v) => [
              MenuOption(title: AppLocalizations.of(context)!.unblockDomain, icon: Icons.check_rounded, action: () => blockUnblock(domain: v, newStatus: 'unblock')),
              MenuOption(title: AppLocalizations.of(context)!.copyClipboard, icon: Icons.copy_rounded, action: () => copyValueClipboard(v)),
            ],
            'onTapEntry': (v) => filterDomainLogs(value: v),
            'isClient': false,
          } as Map<String, dynamic>);
          break;
        case HomeTopItems.recurrentClients:
          cardData.add({
            'type': item,
            'label': AppLocalizations.of(context)!.topClients,
            'color': Colors.teal,
            'data': statusProvider.serverStatus?.stats.topClients ?? [],
            'buildValue': (v) => v.toString(),
            'menuOptions': (v) => [
              if (clientsProvider.clients?.clientsAllowedBlocked != null)
                MenuOption(
                  title: clientsProvider.checkClientList(v) == AccessSettingsList.allowed || clientsProvider.checkClientList(v) == null
                      ? AppLocalizations.of(context)!.blockClient : AppLocalizations.of(context)!.unblockClient,
                  icon: clientsProvider.checkClientList(v) == AccessSettingsList.allowed || clientsProvider.checkClientList(v) == null
                      ? Icons.block_rounded : Icons.check_rounded,
                  action: () => blockUnblockClient(v),
                ),
              MenuOption(title: AppLocalizations.of(context)!.copyClipboard, icon: Icons.copy_rounded, action: () => copyValueClipboard(v)),
            ],
            'onTapEntry': (v) => filterClientLogs(value: v),
            'isClient': true,
          } as Map<String, dynamic>);
          break;
        case HomeTopItems.topUpstreams:
          if (statusProvider.serverStatus?.stats.topUpstreamResponses != null) {
            cardData.add({
              'type': item,
              'label': AppLocalizations.of(context)!.topUpstreams,
              'color': Colors.orange,
              'data': statusProvider.serverStatus?.stats.topUpstreamResponses ?? [],
              'buildValue': (v) => v.toString(),
              'menuOptions': (v) => [
                MenuOption(title: AppLocalizations.of(context)!.copyClipboard, icon: Icons.copy_rounded, action: () => copyValueClipboard(v)),
              ],
              'onTapEntry': null,
              'isClient': false,
            } as Map<String, dynamic>);
          }
          break;
        case HomeTopItems.avgUpstreamResponseTime:
          if (statusProvider.serverStatus?.stats.topUpstreamsAvgTime != null) {
            cardData.add({
              'type': item,
              'label': AppLocalizations.of(context)!.averageUpstreamResponseTime,
              'color': Colors.purple,
              'data': statusProvider.serverStatus?.stats.topUpstreamsAvgTime ?? [],
              'buildValue': (v) => "${doubleFormat(v * 1000, Platform.localeName)} ms",
              'menuOptions': (v) => [
                MenuOption(title: AppLocalizations.of(context)!.copyClipboard, icon: Icons.copy_rounded, action: () => copyValueClipboard(v)),
              ],
              'onTapEntry': null,
              'isClient': false,
            } as Map<String, dynamic>);
          }
          break;
      }
    }

    // Separate client card from the rest
    final clientIndex = cardData.indexWhere((c) => c['isClient'] == true);
    Map<String, dynamic>? clientCard;
    if (clientIndex >= 0) {
      clientCard = cardData.removeAt(clientIndex);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 2-column grid for non-client cards
          Wrap(
            runSpacing: 8,
            spacing: 8,
            children: cardData.asMap().entries.map((entry) {
              final c = entry.value;
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 32 - 8) / 2,
                child: buildCompactCard(
                  label: c['label'],
                  color: c['color'],
                  data: c['data'],
                  buildValue: c['buildValue'],
                  menuOptions: c['menuOptions'],
                  onTapEntry: c['onTapEntry'],
                  isClient: c['isClient'],
                ),
              );
            }).toList(),
          ),
          // Client card at bottom - full width
          if (clientCard != null) ...[
            const SizedBox(height: 8),
            buildCompactCard(
              label: clientCard['label'],
              color: clientCard['color'],
              data: clientCard['data'],
              buildValue: clientCard['buildValue'],
              menuOptions: clientCard['menuOptions'],
              onTapEntry: clientCard['onTapEntry'],
              isClient: clientCard['isClient'],
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  const _MiniRow({required this.label, required this.value, required this.color, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: color.withOpacity(0.7), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface))),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
