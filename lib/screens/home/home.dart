// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:adguard_home_manager/l10n/app_localizations.dart';

import 'package:adguard_home_manager/screens/home/server_status.dart';
import 'package:adguard_home_manager/screens/home/combined_chart.dart';
import 'package:adguard_home_manager/screens/home/appbar.dart';
import 'package:adguard_home_manager/screens/home/fab.dart';

import 'package:adguard_home_manager/providers/clients_provider.dart';
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
                              child: Divider(
                                thickness: 1,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                              ),
                            ),
                            const SizedBox(height: 16),
                                  
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: CombinedHomeChart(),
                            ),

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