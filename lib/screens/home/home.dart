// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:adguard_home_manager/l10n/app_localizations.dart';

import 'package:adguard_home_manager/screens/home/server_status.dart';
import 'package:adguard_home_manager/screens/home/appbar.dart';
import 'package:adguard_home_manager/screens/home/fab.dart';
import 'package:adguard_home_manager/screens/home/top_items/top_items_lists.dart';

import 'package:adguard_home_manager/providers/clients_provider.dart';
import 'package:adguard_home_manager/functions/number_format.dart';
import 'package:adguard_home_manager/constants/enums.dart';
import 'package:adguard_home_manager/providers/status_provider.dart';
import 'package:adguard_home_manager/providers/app_config_provider.dart';
import 'package:adguard_home_manager/functions/snackbar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final ScrollController scrollController = ScrollController();
  late bool isVisible;

  @override
  initState() {
    final statusProvider = Provider.of<StatusProvider>(context, listen: false);
    statusProvider.getServerStatus(
      withLoadingIndicator: statusProvider.serverStatus != null ? false : true
    );

    final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);
    clientsProvider.fetchClients(updateLoading:  false);

    super.initState();

    isVisible = true;
    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (mounted && isVisible == true) {
          setState(() => isVisible = false);
        }
      } 
      else {
        if (scrollController.position.userScrollDirection == ScrollDirection.forward) {
          if (mounted && isVisible == false) {
            setState(() => isVisible = true);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusProvider = Provider.of<StatusProvider>(context);
    final appConfigProvider = Provider.of<AppConfigProvider>(context);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            NestedScrollView(
              controller: scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: HomeAppBar(innerBoxScrolled: innerBoxIsScrolled,)
                )
              ], 
              body: SafeArea(
                top: false,
                bottom: false,
                child: Builder(
                  builder: (context) => RefreshIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    displacement: 110,
                    onRefresh: () async {
                      final result = await statusProvider.getServerStatus();
                      if (mounted && result == false) {
                        showSnackbar(
                          appConfigProvider: appConfigProvider, 
                          label: AppLocalizations.of(context)!.serverStatusNotRefreshed, 
                          color: Colors.red
                        );
                      }
                    },
                    child: CustomScrollView(
                      slivers: [
                        SliverOverlapInjector(
                          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                        ),
                        if (statusProvider.loadStatus == LoadStatus.loading) SliverFillRemaining(
                          child: SizedBox(
                            width: double.maxFinite,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 30),
                                Text(
                                  AppLocalizations.of(context)!.loadingStatus,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                )
                              ],
                            ),
                          )
                        ),
                        if (statusProvider.loadStatus == LoadStatus.loaded) SliverList.list(
                          children: [
                            ServerStatusWidget(serverStatus: statusProvider.serverStatus!),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: SizedBox(height: 60, child: _StatCard(
                                        label: AppLocalizations.of(context)!.dnsQueries,
                                        value: intFormat(statusProvider.serverStatus!.stats.numDnsQueries, Platform.localeName),
                                        sub: "${doubleFormat(statusProvider.serverStatus!.stats.avgProcessingTime*1000, Platform.localeName)} ms",
                                        color: Colors.blue,
                                      ))),
                                      const SizedBox(width: 6),
                                      Expanded(child: SizedBox(height: 60, child: _StatCard(
                                        label: AppLocalizations.of(context)!.blockedFilters,
                                        value: intFormat(statusProvider.serverStatus!.stats.numBlockedFiltering, Platform.localeName),
                                        sub: "${statusProvider.serverStatus!.stats.numDnsQueries > 0 ? doubleFormat((statusProvider.serverStatus!.stats.numBlockedFiltering/statusProvider.serverStatus!.stats.numDnsQueries)*100, Platform.localeName) : 0}%",
                                        color: Colors.red,
                                      ))),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(child: SizedBox(height: 60, child: _StatCard(
                                        label: AppLocalizations.of(context)!.malwarePhishingBlocked,
                                        value: intFormat(statusProvider.serverStatus!.stats.numReplacedSafebrowsing, Platform.localeName),
                                        sub: "${statusProvider.serverStatus!.stats.numDnsQueries > 0 ? doubleFormat((statusProvider.serverStatus!.stats.numReplacedSafebrowsing/statusProvider.serverStatus!.stats.numDnsQueries)*100, Platform.localeName) : 0}%",
                                        color: Colors.green,
                                      ))),
                                      const SizedBox(width: 6),
                                      Expanded(child: SizedBox(height: 60, child: _StatCard(
                                        label: AppLocalizations.of(context)!.blockedAdultWebsites,
                                        value: intFormat(statusProvider.serverStatus!.stats.numReplacedParental, Platform.localeName),
                                        sub: "${statusProvider.serverStatus!.stats.numDnsQueries > 0 ? doubleFormat((statusProvider.serverStatus!.stats.numReplacedParental/statusProvider.serverStatus!.stats.numDnsQueries)*100, Platform.localeName) : 0}%",
                                        color: Colors.orange,
                                      ))),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            TopItemsLists(order: appConfigProvider.homeTopItemsOrder),

                            const SizedBox(height: 16),
                          ],
                        ),
                        if (statusProvider.loadStatus == LoadStatus.error) SliverFillRemaining(
                          child: SizedBox(
                            width: double.maxFinite,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 50,
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  AppLocalizations.of(context)!.errorLoadServerStatus,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                )
                              ],
                            ),
                          )
                        ),
                      ],
                    )
                  ),
                )
              )
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              bottom: isVisible == true ?
                appConfigProvider.showingSnackbar
                  ? 70 
                  : 20
                : -70,
              right: 20,
              child: const HomeFab() 
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}