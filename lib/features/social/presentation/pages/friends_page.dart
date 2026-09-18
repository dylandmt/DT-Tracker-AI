import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    await _run(() async {
      final results = await _social.searchUsers(query);
      if (mounted) {
        setState(() => _searchResults = results);
      }
    }, reload: false);
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _showShareDialog(Map<String, dynamic> friend) async {
    final uid = _uid(friend);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (uid.isEmpty || currentUser == null) return;
    List<QueryDocumentSnapshot<Map<String, dynamic>>> vehicles;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('vehicles')
          .where('trackerId', isNull: false)
          .get();
      vehicles = snapshot.docs;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
      return;
    }
    if (!mounted) return;
    final selected = <String>{};
    var duration = '15m';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Share location with ${_name(friend)}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (vehicles.isEmpty)
                  const Text(
                    'No vehicles with a linked tracker are available.',
                  ),
                ...vehicles.map(
                  (vehicle) => CheckboxListTile(
                    value: selected.contains(vehicle.id),
                    title: Text(
                      vehicle.data()['name']?.toString() ?? vehicle.id,
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
                ),
                DropdownButtonFormField<String>(
                  initialValue: duration,
                  decoration: const InputDecoration(labelText: 'Duration'),
                  items: const ['15m', '30m', '1h', '4h', '8h', 'until_revoked']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => duration = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      await _run(
                        () => _social
                            .upsertLocationShare(
                              friendUid: uid,
                              vehicleIds: selected.toList(),
                              duration: duration,
                            )
                            .then((_) {}),
                      );
                    },
              child: const Text('Share'),
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
      title: const Text('Friends & location sharing'),
      actions: [
        IconButton(
          onPressed: _working ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) _errorCard(),
                _searchCard(),
                _section(
                  'Incoming requests',
                  _incoming.map(_incomingTile).toList(),
                  empty: 'No incoming requests.',
                ),
                _section(
                  'Outgoing requests',
                  _outgoing.map(_outgoingTile).toList(),
                  empty: 'No outgoing requests.',
                ),
                _section(
                  'Friends',
                  _friends.map(_friendTile).toList(),
                  empty: 'No friends yet.',
                ),
                _section(
                  'Received location shares',
                  _incomingShares.map(_incomingShareTile).toList(),
                  empty: 'No received shares.',
                ),
                _section(
                  'Your location shares',
                  _outgoingShares.map(_outgoingShareTile).toList(),
                  empty: 'No active or previous shares.',
                ),
                _section(
                  'Blocked users',
                  _blocks.map(_blockTile).toList(),
                  empty: 'No blocked users.',
                ),
              ],
            ),
          ),
  );

  Widget _searchCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Exact username or email',
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              IconButton(
                onPressed: _working ? null : _search,
                icon: const Icon(Icons.search),
              ),
            ],
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
                child: const Text('Add'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _incomingTile(Map<String, dynamic> request) => ListTile(
    title: Text(_name(_user(request))),
    subtitle: const Text('Wants to be your friend'),
    trailing: Wrap(
      spacing: 4,
      children: [
        IconButton(
          onPressed: _working
              ? null
              : () => _run(
                  () => _social.acceptRequest(request['requestId'].toString()),
                ),
          icon: const Icon(Icons.check),
        ),
        IconButton(
          onPressed: _working
              ? null
              : () => _run(
                  () => _social.rejectRequest(request['requestId'].toString()),
                ),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
  Widget _outgoingTile(Map<String, dynamic> request) => ListTile(
    title: Text(_name(_user(request))),
    subtitle: const Text('Request pending'),
    trailing: TextButton(
      onPressed: _working
          ? null
          : () => _run(
              () => _social.cancelRequest(request['requestId'].toString()),
            ),
      child: const Text('Cancel'),
    ),
  );
  Widget _friendTile(Map<String, dynamic> friend) => ListTile(
    title: Text(_name(_user(friend))),
    subtitle: Text(_user(friend)['username']?.toString() ?? ''),
    trailing: PopupMenuButton<String>(
      onSelected: (action) {
        final user = _user(friend);
        if (action == 'share') _showShareDialog(user);
        if (action == 'remove') _run(() => _social.removeFriend(_uid(user)));
        if (action == 'block') _run(() => _social.blockUser(_uid(user)));
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'share', child: Text('Share location')),
        PopupMenuItem(value: 'remove', child: Text('Remove friend')),
        PopupMenuItem(value: 'block', child: Text('Block')),
      ],
    ),
  );
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
              title: Text('Share from ${share['ownerUid']}'),
              subtitle: Text(_shareDescription(share)),
              trailing: TextButton(
                onPressed: _working ? null : () => _loadLocations(id),
                child: const Text('Locations'),
              ),
            ),
            if (locations != null)
              ...locations.map(
                (location) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(
                    '${location['lat'] ?? '-'}, ${location['lng'] ?? '-'}',
                  ),
                  subtitle: Text(
                    'Vehicle ${location['vehicleId'] ?? '-'} | ${_freshness(location['receivedAt'] ?? location['datetime'])}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _outgoingShareTile(Map<String, dynamic> share) => ListTile(
    title: Text('To ${share['recipientUid']}'),
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
            child: const Text('Revoke'),
          )
        : null,
  );
  Widget _blockTile(Map<String, dynamic> block) {
    final uid = block['blockedUid']?.toString() ?? '';
    return ListTile(
      title: Text(uid),
      subtitle: const Text('Blocked'),
      trailing: TextButton(
        onPressed: _working ? null : () => _run(() => _social.unblockUser(uid)),
        child: const Text('Unblock'),
      ),
    );
  }

  Widget _section(
    String title,
    List<Widget> children, {
    required String empty,
  }) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
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
      '${(share['vehicleIds'] as List? ?? const []).length} vehicle(s) | ${share['duration'] ?? '15m'} | ${share['status'] ?? ''}';
  String _freshness(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'No timestamp';
    final minutes = DateTime.now().difference(date.toLocal()).inMinutes;
    return minutes < 1 ? 'Just now' : '$minutes min ago';
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
