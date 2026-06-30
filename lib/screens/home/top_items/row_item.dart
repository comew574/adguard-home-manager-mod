import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adguard_home_manager/l10n/app_localizations.dart';

import 'package:adguard_home_manager/widgets/options_menu.dart';
import 'package:adguard_home_manager/models/menu_option.dart';
import 'package:adguard_home_manager/constants/enums.dart';
import 'package:adguard_home_manager/providers/status_provider.dart';

class RowItem extends StatelessWidget {
  final HomeTopItems type;
  final Color chartColor;
  final String domain;
  final String number;
  final bool clients;
  final bool showColor;
  final String? unit;
  final List<MenuOption> Function(dynamic) options;
  final void Function(dynamic)? onTapEntry;

  const RowItem({
    super.key,
    required this.type,
    required this.chartColor,
    required this.domain,
    required this.number,
    required this.clients,
    required this.showColor,
    required this.options,
    this.onTapEntry,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final statusProvider = Provider.of<StatusProvider>(context);

    String? name;
    if (clients == true) {
      try {
        name = statusProvider.serverStatus!.clients.firstWhere((c) => c.ids.contains(domain)).name;
      } catch (e) {
        // ---- //
      }
    }

    return Material(
      color: Colors.transparent,
      child: OptionsMenu(
        value: domain,
        options: options,
        onTap: onTapEntry,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: chartColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            domain,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (name != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: chartColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: chartColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OthersRowItem extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool showColor;

  const OthersRowItem({
    super.key,
    required this.items,
    required this.showColor,
  });

  @override
  Widget build(BuildContext context) {
    if (items.length <= 5) {
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.others,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              List<int>.from(
                items.sublist(5, items.length).map((e) => e.values.first.toInt())
              ).reduce((a, b) => a + b).toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
