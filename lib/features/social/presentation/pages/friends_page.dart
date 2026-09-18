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
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    await _run(() async {
      _searchResults = await _social.searchUsers(query);
    }, reload: false);
  }

  void _onSearchChanged(String _) {
    setState(() => _searchResults = []);
  }

  Future<void> _sendFriendRequest(Map<String, dynamic> user) => _run(() async {
    await _social.sendFriendRequest(_uid(user));
    if (mounted) {
      setState(() {
        _searchController.clear();
        _searchResults = [];
      });
    }
  });

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
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.friends),
        actions: [
          IconButton(
            onPressed: _working ? null : _load,
            tooltip: context.l10n.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          tabs: [
            Tab(text: context.l10n.myFriends),
            Tab(text: context.l10n.requests),
            Tab(text: context.l10n.locationsTab),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading || _working ? null : _startShareFlow,
        icon: const Icon(Icons.share_location_outlined),
        label: Text(context.l10n.shareLocation),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              children: [
                _myFriendsTab(),
                _requestsTab(),
                _tabContent(_locationsContent()),
              ],
            ),
    ),
  );

  Widget _tabContent(List<Widget> children) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: children,
    ),
  );

  Widget _myFriendsTab() {
    final friends = [..._friends.map(_friendTile), ..._blocks.map(_blockTile)];
    if (friends.isEmpty) {
      return Column(
        children: [
          Padding(padding: const EdgeInsets.all(16), child: _searchCard()),
          Expanded(child: Center(child: Text(context.l10n.noFriendsYet))),
        ],
      );
    }
    return _tabContent([
      if (_error != null) _errorCard(),
      _searchCard(),
      _section(context.l10n.friends, friends, empty: context.l10n.noFriendsYet),
    ]);
  }

  List<Widget> _requestsContent() => [
    if (_error != null) _errorCard(),
    _section(context.l10n.friendRequests, [
      ..._incoming.map(_incomingTile),
      ..._outgoing.map(_outgoingTile),
    ], empty: context.l10n.noFriendRequests),
  ];

  Widget _requestsTab() {
    if (_incoming.isEmpty && _outgoing.isEmpty) {
      return Center(child: Text(context.l10n.noFriendRequests));
    }
    return _tabContent(_requestsContent());
  }

  List<Widget> _locationsContent() => [
    if (_error != null) _errorCard(),
    _section(
      context.l10n.yourLocationShares,
      _outgoingShares
          .map((share) => _locationShareTile(share, outgoing: true))
          .toList(),
      empty: context.l10n.noLocationShares,
    ),
    _section(
      context.l10n.receivedLocationShares,
      _incomingShares
          .map((share) => _locationShareTile(share, outgoing: false))
          .toList(),
      empty: context.l10n.noReceivedShares,
    ),
  ];

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
            onChanged: _onSearchChanged,
            onSubmitted: (_) => _search(),
          ),
          if (_searchController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._matchingFriends().map(_friendTile),
          ],
          ..._searchResults.map((user) => _friendSearchTile(user)),
        ],
      ),
    ),
  );

  List<Map<String, dynamic>> _matchingFriends() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _friends.where((friend) {
      final user = _user(friend);
      return [
        _name(user),
        _nickname(user),
        user['email']?.toString() ?? '',
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  Widget _friendSearchTile(Map<String, dynamic> user) {
    if (_friends.any((friend) => _uid(_user(friend)) == _uid(user))) {
      return const SizedBox.shrink();
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: _avatar(user),
      title: Text(_name(user)),
      subtitle: Text(_nickname(user)),
      trailing: FilledButton(
        onPressed: _working ? null : () => _sendFriendRequest(user),
        child: Text(context.l10n.addFriend),
      ),
    );
  }

  Widget _incomingTile(Map<String, dynamic> request) {
    final user = _user(request);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name(user),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (_nickname(user).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(_nickname(user)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _working
                              ? null
                              : () => _run(
                                  () => _social.acceptRequest(
                                    request['requestId'].toString(),
                                  ),
                                ),
                          child: Text(context.l10n.accept),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _working
                              ? null
                              : () => _run(
                                  () => _social.rejectRequest(
                                    request['requestId'].toString(),
                                  ),
                                ),
                          child: Text(context.l10n.reject),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outgoingTile(Map<String, dynamic> request) {
    final user = _user(request);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: _avatar(user),
        title: Text(_name(user)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_nickname(user).isNotEmpty) Text(_nickname(user)),
            Text(context.l10n.friendRequestPending),
          ],
        ),
        trailing: TextButton(
          onPressed: _working
              ? null
              : () => _run(
                  () => _social.cancelRequest(request['requestId'].toString()),
                ),
          child: Text(context.l10n.cancel),
        ),
      ),
    );
  }

  Widget _friendTile(Map<String, dynamic> friend) {
    final user = _user(friend);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: _avatar(user),
        title: Text(_name(user)),
        subtitle: _nickname(user).isEmpty ? null : Text(_nickname(user)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _statusLabel(context.l10n.friendsStatus, Icons.check_circle),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: (action) {
                if (action == 'remove') {
                  _run(() => _social.removeFriend(_uid(user)));
                }
                if (action == 'block') {
                  _run(() => _social.blockUser(_uid(user)));
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'remove',
                  child: Text(context.l10n.removeFriend),
                ),
                PopupMenuItem(value: 'block', child: Text(context.l10n.block)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationShareTile(
    Map<String, dynamic> share, {
    required bool outgoing,
  }) {
    final id = share['shareId'].toString();
    final locations = _locations[id];
    final user = _shareUser(share, outgoing: outgoing);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _avatar(user),
              title: Text(_name(user)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outgoing
                        ? context.l10n.shareTo(_name(user))
                        : context.l10n.shareFrom(_name(user)),
                  ),
                  if (_nickname(user).isNotEmpty) Text(_nickname(user)),
                  Text(_shareDescription(share)),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'locations') _loadLocations(id);
                  if (action == 'revoke') {
                    _run(() => _social.revokeLocationShare(id));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'locations',
                    child: Text(context.l10n.locations),
                  ),
                  if (outgoing && share['status'] == 'active')
                    PopupMenuItem(
                      value: 'revoke',
                      child: Text(context.l10n.revoke),
                    ),
                ],
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

  Map<String, dynamic> _shareUser(
    Map<String, dynamic> share, {
    required bool outgoing,
  }) {
    final profileKey = outgoing ? 'recipient' : 'owner';
    final profile = share[profileKey] ?? share['user'];
    if (profile is Map) return Map<String, dynamic>.from(profile);

    final uid =
        (outgoing ? share['recipientUid'] : share['ownerUid'])?.toString() ??
        '';
    for (final friend in _friends) {
      final user = _user(friend);
      if (_uid(user) == uid) return user;
    }
    return {'uid': uid};
  }

  Widget _blockTile(Map<String, dynamic> block) {
    final uid = block['blockedUid']?.toString() ?? '';
    final user = _user(block);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Opacity(
            opacity: 0.7,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 96),
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(12, 6, 130, 6),
                leading: _avatar(user),
                title: Text(_name(user).isEmpty ? uid : _name(user)),
                subtitle: _nickname(user).isEmpty
                    ? null
                    : Text(_nickname(user)),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusLabel(context.l10n.blocked, Icons.block),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: _working
                      ? null
                      : () => _run(() => _social.unblockUser(uid)),
                  child: Text(context.l10n.unblock),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(Map<String, dynamic> user) {
    final photoUrl = _photoUrl(user);
    return CircleAvatar(
      radius: 26,
      foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
      child: Text(_name(user).isEmpty ? '?' : _name(user)[0].toUpperCase()),
    );
  }

  Widget _statusLabel(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );

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

  Widget _errorCard() => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
  );

  Map<String, dynamic> _user(Map<String, dynamic> item) => item['user'] is Map
      ? Map<String, dynamic>.from(item['user'] as Map)
      : item;

  String _uid(Map<String, dynamic> user) =>
      user['uid']?.toString() ?? user['friendUid']?.toString() ?? '';

  String _nickname(Map<String, dynamic> user) {
    final username = user['username']?.toString() ?? '';
    return username.isEmpty ? '' : '@$username';
  }

  String? _photoUrl(Map<String, dynamic> user) {
    for (final key in ['photoUrl', 'photoURL', 'avatarUrl', 'imageUrl']) {
      final value = user[key]?.toString();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

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
