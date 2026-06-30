// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:adguard_home_manager/l10n/app_localizations.dart';


import 'package:adguard_home_manager/screens/home/top_items/row_item.dart';
import 'package:adguard_home_manager/screens/home/top_items/top_items_screen.dart';

import 'package:adguard_home_manager/models/menu_option.dart';
import 'package:adguard_home_manager/constants/enums.dart';

class TopItemsSection extends StatelessWidget {
  final HomeTopItems type;
  final String label;
  final List<Map<String, dynamic>> data;
  final bool withChart;
  final bool withProgressBar;
  final String Function(dynamic) buildValue;
  final List<MenuOption> Function(dynamic) menuOptions;
  final void Function(dynamic)? onTapEntry;

  const TopItemsSection({
    super.key,
    required this.type,
    required this.label,
    required this.data,
    required this.withChart,
    required this.withProgressBar,
    required this.buildValue,
    required this.menuOptions,
    this.onTapEntry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.red, 
      Colors.green, 
      Colors.blue, 
      Colors.orange,
      Colors.teal, 
      Colors.grey
    ];

    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.isEmpty) _NoData(label: label),
          if (data.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _ItemsList(
                    colors: colors, 
                    data: data, 
                    clients: type == HomeTopItems.recurrentClients, 
                    type: type, 
                    showChart: false,
                    buildValue: buildValue,
                    menuOptions: menuOptions,
                    onTapEntry: onTapEntry,
                  ),
                  if (data.length > 5) ...[                  
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => {
                              if (width > 700) {
                                showDialog(
                                  context: context, 
                                  builder: (context) => TopItemsScreen(
                                    type: type,
                                    title: label,
                                    isClient: type == HomeTopItems.recurrentClients, 
                                    data: data,
                                    withProgressBar: withProgressBar,
                                    buildValue: buildValue,
                                    options: menuOptions,
                                    onTapEntry: onTapEntry,
                                    isFullscreen: !(width > 700 || !(Platform.isAndroid | Platform.isIOS)),
                                  ),
                                )
                              }
                              else {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => TopItemsScreen(
                                    type: type,
                                    title: label,
                                    isClient: type == HomeTopItems.recurrentClients, 
                                    data: data,
                                    withProgressBar: withProgressBar,
                                    buildValue: buildValue,
                                    options: menuOptions,
                                    onTapEntry: onTapEntry,
                                    isFullscreen: !(width > 700 || !(Platform.isAndroid | Platform.isIOS)),
                                  ),
                                ))
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.viewMore,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                )
                              ],
                            )
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 16),
          ]
        ],
      ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  final List<Color> colors;
  final List<Map<String, dynamic>> data;
  final bool? clients;
  final HomeTopItems type;
  final bool showChart;
  final String Function(dynamic) buildValue;
  final List<MenuOption> Function(dynamic) menuOptions;
  final void Function(dynamic)? onTapEntry;
    
  const _ItemsList({
    required this.colors,
    required this.data,
    required this.clients,
    required this.type,
    required this.showChart,
    required this.buildValue,
    required this.menuOptions,
    this.onTapEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: data.sublist(
        0, data.length > 5 ? 5 : data.length
      ).asMap().entries.map((e) => RowItem(
        clients: clients ?? false,
        domain: e.value.keys.toList()[0],
        number: buildValue(e.value.values.toList()[0]),
        type: type,
        chartColor: colors[e.key],
        showColor: showChart,
        options: menuOptions,
        onTapEntry: onTapEntry,
      )).toList() 
    );
  }
}

class _NoData extends StatelessWidget {
  final String label;

  const _NoData({
    required this.label
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
