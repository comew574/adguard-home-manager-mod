import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adguard_home_manager/l10n/app_localizations.dart';


import 'package:adguard_home_manager/screens/home/status_box.dart';
import 'package:adguard_home_manager/providers/filtering_provider.dart';
import 'package:adguard_home_manager/providers/clients_provider.dart';

import 'package:adguard_home_manager/models/server_status.dart';

class ServerStatusWidget extends StatelessWidget {
  final ServerStatus serverStatus;

  const ServerStatusWidget({
    super.key,
    required this.serverStatus,
  });

  void _showBlockList(BuildContext context) {
    final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);
    final blocked = clientsProvider.clients?.clientsAllowedBlocked?.disallowedClients ?? [];
    final allowed = clientsProvider.clients?.clientsAllowedBlocked?.allowedClients ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('黑白名单'),
        content: SizedBox(
          width: double.maxFinite,
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: '黑名单'),
                    Tab(text: '白名单'),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      blocked.isEmpty
                        ? const Center(child: Text('暂无黑名单'))
                        : ListView.builder(
                            itemCount: blocked.length,
                            itemBuilder: (_, i) => ListTile(
                              dense: true,
                              title: Text(blocked[i].toString()),
                            ),
                          ),
                      allowed.isEmpty
                        ? const Center(child: Text('暂无白名单'))
                        : ListView.builder(
                            itemCount: allowed.length,
                            itemBuilder: (_, i) => ListTile(
                              dense: true,
                              title: Text(allowed[i].toString()),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  void _showCustomRules(BuildContext context) {
    final filteringProvider = Provider.of<FilteringProvider>(context, listen: false);
    final rules = filteringProvider.filtering?.userRules ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('自定义规则'),
        content: SizedBox(
          width: double.maxFinite,
          child: rules.isEmpty
            ? const Center(child: Text('暂无自定义规则'))
            : SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: rules.length,
                  itemBuilder: (_, i) => ListTile(
                    dense: true,
                    title: Text(
                      rules[i],
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.serverStatus,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface
            ),
          ),
          const SizedBox(height: 12),
          GridView(
            primary: false,
            shrinkWrap: true,
            padding: const EdgeInsets.all(0),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: width > 700 ? 4 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 60 * textScaleFactor
            ),
            children: [
              StatusBox(
                icon: Icons.filter_list_rounded, 
                label: AppLocalizations.of(context)!.ruleFilteringWidget, 
                isEnabled: serverStatus.filteringEnabled
              ),
              StatusBox(
                icon: Icons.vpn_lock_rounded, 
                label: AppLocalizations.of(context)!.safeBrowsingWidget, 
                isEnabled: serverStatus.safeBrowsingEnabled
              ),
              StatusBox(
                icon: Icons.block, 
                label: AppLocalizations.of(context)!.parentalFilteringWidget, 
                isEnabled: serverStatus.parentalControlEnabled
              ),
              StatusBox(
                icon: Icons.search_rounded, 
                label: AppLocalizations.of(context)!.safeSearchWidget, 
                isEnabled: serverStatus.safeSearchEnabled
              ),
              StatusBox(
                icon: Icons.shield_rounded,
                label: '黑白名单',
                isEnabled: true,
                onTap: () => _showBlockList(context),
              ),
              StatusBox(
                icon: Icons.edit_note_rounded,
                label: '自定义规则',
                isEnabled: true,
                onTap: () => _showCustomRules(context),
              ),
            ],
          )
        ],
      ),
    );
  }
}
