import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/social_backend_datasource.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _searchController = TextEditingController();
  late final SocialBackendDataSource _social;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _incoming = [];
  List<Map<String, dynamic>> _outgoing = [];
  List<Map<String, dynamic>> _blocks = [];
  List<Map<String, dynamic>> _incomingShares = [];
  List<Map<String, dynamic>> _outgoingShares = [];
  final Map<String, List<Map<String, dynamic>>> _locations = {};
  List<Map<String, dynamic>> _searchResults = [];
  bool _loading = true;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _social = sl<SocialBackendDataSource>();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        _social.friends(),
        _social.incomingRequests(),
        _social.outgoingRequests(),
        _social.blocks(),
        _social.incomingLocationShares(),
        _social.outgoingLocationShares(),
      ]);
      if (!mounted) return;
      setState(() {
        _friends = values[0];
        _incoming = values[1];
        _outgoing = values[2];
        _blocks = values[3];
        _incomingShares = values[4];
        _outgoingShares = values[5];
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(
    Future<void> Function() action, {
    bool reload = true,
  }) async {
    setState(() => _working = true);
    try {
      await action();
      if (reload) await _load();
    } catch (error) {
      if (mounted) context.showErrorSnackBar(_message(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    await _run(() async {
      _searchResults = await _social.searchUsers(query);
    }, reload: false);
  }

  Future<void> _startShareFlow() async {
    await context.push(RouteConstants.shareLocation);
    if (mounted) await _load();
  }

  // ignore: unused_element
  Future<void> _legacyStartShareFlow() async {
    if (_friends.isEmpty) {
      context.showErrorSnackBar(context.l10n.shareNoFriends);
      return;
    }
    final friend = await _selectFriend();
    if (friend == null || !mounted) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      context.showErrorSnackBar(context.l10n.socialAuthenticationRequired);
      return;
    }

    List<QueryDocumentSnapshot<Map<String, dynamic>>> vehicles;
    try {
      vehicles = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('vehicles')
          .where('trackerId', isNull: false)
          .get()
          .then((snapshot) => snapshot.docs);
    } catch (error) {
      if (mounted) context.showErrorSnackBar(_message(error));
      return;
    }
    if (!mounted) return;
    if (vehicles.isEmpty) {
      context.showErrorSnackBar(context.l10n.shareNoLinkedVehicles);
      return;
    }
    final vehicleIds = await _selectVehicles(vehicles);
    if (vehicleIds == null || vehicleIds.isEmpty || !mounted) return;
    final duration = await _selectDuration();
    if (duration == null || !mounted) return;
    await _run(
      () async => _social.upsertLocationShare(
        friendUid: _uid(_user(friend)),
        vehicleIds: vehicleIds,
        duration: duration,
      ),
    );
  }

  Future<Map<String, dynamic>?> _selectFriend() =>
      showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.shareSelectFriendTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _friends
                  .map(
                    (friend) => ListTile(
                      title: Text(_name(_user(friend))),
                      subtitle: Text(
                        _user(friend)['username']?.toString() ?? '',
                      ),
                      onTap: () => Navigator.pop(dialogContext, friend),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.cancel),
            ),
          ],
        ),
      );

  Future<List<String>?> _selectVehicles(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> vehicles,
  ) async {
    final selected = <String>{};
    return showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.shareSelectVehiclesTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: vehicles
                  .map(
                    (vehicle) => CheckboxListTile(
                      value: selected.contains(vehicle.id),
                      title: Text(
                        vehicle.data()['name']?.toString() ??
                            context.l10n.vehicle,
                      ),
                      subtitle: Text(
                        vehicle.data()['plateNumber']?.toString() ?? '',
                      ),
                      onChanged: (value) => setDialogState(
                        () => value == true
                            ? selected.add(vehicle.id)
                            : selected.remove(vehicle.id),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, selected.toList()),
              child: Text(context.l10n.next),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _selectDuration() async {
    var duration = '15m';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.shareSelectDurationTitle),
          content: DropdownButtonFormField<String>(
            initialValue: duration,
            decoration: InputDecoration(labelText: context.l10n.duration),
            items: ['15m', '30m', '1h', '4h', '8h', 'until_revoked']
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_durationLabel(context, value)),
                  ),
                )
                .toList(),
            onChanged: (value) => setDialogState(() => duration = value!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, duration),
              child: Text(context.l10n.shareLocation),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadLocations(String shareId) => _run(() async {
    final result = await _social.sharedLocations(shareId);
    final items = result['locations'] as List? ?? const [];
    if (mounted) {
      setState(
        () => _locations[shareId] = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );
    }
  }, reload: false);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.friends),
      actions: [
        IconButton(
          onPressed: _working ? null : _load,
          tooltip: context.l10n.refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _loading || _working ? null : _startShareFlow,
      icon: const Icon(Icons.share_location_outlined),
      label: Text(context.l10n.shareLocation),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) _errorCard(),
                _section(
                  context.l10n.friends,
                  _friends.map(_friendTile).toList(),
                  empty: context.l10n.noFriendsYet,
                ),
                _searchCard(),
                _secondarySection(context.l10n.friendRequests, [
                  _subsection(
                    context.l10n.incomingRequests,
                    _incoming.map(_incomingTile).toList(),
                    context.l10n.noIncomingRequests,
                  ),
                  _subsection(
                    context.l10n.outgoingRequests,
                    _outgoing.map(_outgoingTile).toList(),
                    context.l10n.noOutgoingRequests,
                  ),
                ]),
                _secondarySection(context.l10n.locationSharing, [
                  _subsection(
                    context.l10n.receivedLocationShares,
                    _incomingShares.map(_incomingShareTile).toList(),
                    context.l10n.noReceivedShares,
                  ),
                  _subsection(
                    context.l10n.yourLocationShares,
                    _outgoingShares.map(_outgoingShareTile).toList(),
                    context.l10n.noLocationShares,
                  ),
                ]),
                _secondarySection(context.l10n.blockedUsers, [
                  _subsection(
                    '',
                    _blocks.map(_blockTile).toList(),
                    context.l10n.noBlockedUsers,
                  ),
                ]),
              ],
            ),
          ),
  );

  Widget _searchCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: context.l10n.friendSearchLabel,
              suffixIcon: IconButton(
                onPressed: _working ? null : _search,
                tooltip: context.l10n.search,
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
          ..._searchResults.map(
            (user) => ListTile(
              title: Text(_name(user)),
              subtitle: Text(
                user['email']?.toString() ?? user['username']?.toString() ?? '',
              ),
              trailing: FilledButton(
                onPressed: _working
                    ? null
                    : () => _run(() => _social.sendFriendRequest(_uid(user))),
                child: Text(context.l10n.addFriend),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _incomingTile(Map<String, dynamic> request) => ListTile(
    title: Text(_name(_user(request))),
    subtitle: Text(context.l10n.friendRequestReceived),
    trailing: Wrap(
      spacing: 4,
      children: [
        IconButton(
          onPressed: _working
              ? null
              : () => _run(
                  () => _social.acceptRequest(request['requestId'].toString()),
                ),
          tooltip: context.l10n.accept,
          icon: const Icon(Icons.check),
        ),
        IconButton(
          onPressed: _working
              ? null
              : () => _run(
                  () => _social.rejectRequest(request['requestId'].toString()),
                ),
          tooltip: context.l10n.reject,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );

  Widget _outgoingTile(Map<String, dynamic> request) => ListTile(
    title: Text(_name(_user(request))),
    subtitle: Text(context.l10n.friendRequestPending),
    trailing: TextButton(
      onPressed: _working
          ? null
          : () => _run(
              () => _social.cancelRequest(request['requestId'].toString()),
            ),
      child: Text(context.l10n.cancel),
    ),
  );

  Widget _friendTile(Map<String, dynamic> friend) {
    final user = _user(friend);
    return ListTile(
      title: Text(_name(user)),
      subtitle: Text(user['username']?.toString() ?? ''),
      trailing: PopupMenuButton<String>(
        onSelected: (action) {
          if (action == 'remove') _run(() => _social.removeFriend(_uid(user)));
          if (action == 'block') _run(() => _social.blockUser(_uid(user)));
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'remove',
            child: Text(context.l10n.removeFriend),
          ),
          PopupMenuItem(value: 'block', child: Text(context.l10n.block)),
        ],
      ),
    );
  }

  Widget _incomingShareTile(Map<String, dynamic> share) {
    final id = share['shareId'].toString();
    final locations = _locations[id];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                context.l10n.shareFrom(share['ownerUid']?.toString() ?? ''),
              ),
              subtitle: Text(_shareDescription(share)),
              trailing: TextButton(
                onPressed: _working ? null : () => _loadLocations(id),
                child: Text(context.l10n.locations),
              ),
            ),
            if (locations != null)
              ...locations.map(
                (location) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(
                    '${location['lat'] ?? context.l10n.notAvailable}, ${location['lng'] ?? context.l10n.notAvailable}',
                  ),
                  subtitle: Text(
                    context.l10n.sharedLocationDetails(
                      location['vehicleId']?.toString() ??
                          context.l10n.notAvailable,
                      _freshness(
                        location['receivedAt'] ?? location['datetime'],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _outgoingShareTile(Map<String, dynamic> share) => ListTile(
    title: Text(context.l10n.shareTo(share['recipientUid']?.toString() ?? '')),
    subtitle: Text(_shareDescription(share)),
    trailing: share['status'] == 'active'
        ? TextButton(
            onPressed: _working
                ? null
                : () => _run(
                    () => _social.revokeLocationShare(
                      share['shareId'].toString(),
                    ),
                  ),
            child: Text(context.l10n.revoke),
          )
        : null,
  );

  Widget _blockTile(Map<String, dynamic> block) {
    final uid = block['blockedUid']?.toString() ?? '';
    return ListTile(
      title: Text(uid),
      subtitle: Text(context.l10n.blocked),
      trailing: TextButton(
        onPressed: _working ? null : () => _run(() => _social.unblockUser(uid)),
        child: Text(context.l10n.unblock),
      ),
    );
  }

  Widget _section(
    String title,
    List<Widget> children, {
    required String empty,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        if (children.isEmpty) Text(empty) else ...children,
      ],
    ),
  );

  Widget _secondarySection(String title, List<Widget> children) =>
      ExpansionTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        children: children,
      );

  Widget _subsection(String title, List<Widget> children, String empty) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            if (children.isEmpty) Text(empty) else ...children,
          ],
        ),
      );

  Widget _errorCard() => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
  );

  Map<String, dynamic> _user(Map<String, dynamic> item) => item['user'] is Map
      ? Map<String, dynamic>.from(item['user'] as Map)
      : item;

  String _uid(Map<String, dynamic> user) =>
      user['uid']?.toString() ?? user['friendUid']?.toString() ?? '';

  String _name(Map<String, dynamic> user) {
    final name = [
      user['firstName'],
      user['lastName'],
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');
    return name.isNotEmpty
        ? name
        : user['username']?.toString() ??
              user['email']?.toString() ??
              _uid(user);
  }

  String _shareDescription(Map<String, dynamic> share) =>
      context.l10n.shareSummary(
        (share['vehicleIds'] as List? ?? const []).length,
        _durationLabel(context, share['duration']?.toString() ?? '15m'),
        _shareStatus(context, share['status']?.toString()),
      );

  String _durationLabel(BuildContext context, String duration) =>
      switch (duration) {
        '15m' => context.l10n.shareDuration15Minutes,
        '30m' => context.l10n.shareDuration30Minutes,
        '1h' => context.l10n.shareDuration1Hour,
        '4h' => context.l10n.shareDuration4Hours,
        '8h' => context.l10n.shareDuration8Hours,
        'until_revoked' => context.l10n.shareDurationUntilRevoked,
        _ => duration,
      };

  String _shareStatus(BuildContext context, String? status) => switch (status) {
    'active' => context.l10n.shareStatusActive,
    'revoked' => context.l10n.shareStatusRevoked,
    'expired' => context.l10n.shareStatusExpired,
    _ => context.l10n.shareStatusUnknown,
  };

  String _freshness(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? context.l10n.noTimestamp
        : date.localizedTimeAgo(context);
  }

  String _message(Object error) => error.toString();
}
