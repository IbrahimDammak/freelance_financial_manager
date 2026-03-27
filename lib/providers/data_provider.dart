import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/client.dart';
import '../models/project.dart';
import '../models/work_session.dart';
import '../utils.dart';

class DataProvider extends ChangeNotifier {
  DataProvider(this._clientsBox) {
    reload();
  }

  final Box _clientsBox;

  final List<Client> _clients = [];
  bool hasError = false;
  String errorMessage = '';
  String? lastError;

  List<Client> get clients => List.unmodifiable(_clients);

  List<Client> get sortedClients {
    final copy = [..._clients];
    copy.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return copy;
  }

  Future<void> reload() async {
    try {
      final loaded =
          (_clientsBox.get('all') as List?)?.cast<Client>() ?? <Client>[];
      _clients
        ..clear()
        ..addAll(loaded);
      hasError = false;
      errorMessage = '';
      lastError = null;
    } catch (error) {
      hasError = true;
      errorMessage = 'Failed to load clients. Please retry.';
      lastError = error.toString();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      await _clientsBox.put('all', _clients);
      hasError = false;
      errorMessage = '';
      lastError = null;
    } catch (error) {
      hasError = true;
      errorMessage = 'Could not save local changes.';
      lastError = error.toString();
    }
    notifyListeners();
  }

  Future<void> addClient(Client client) async {
    _clients.add(client);
    await _persist();
  }

  Future<void> deleteClient(String clientId) async {
    _clients.removeWhere((client) => client.id == clientId);
    await _persist();
  }

  Client? findClient(String id) {
    try {
      return _clients.firstWhere((client) => client.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addProject(String clientId, Project project) async {
    final client = findClient(clientId);
    if (client == null) return;
    client.projects.add(project);
    await _persist();
  }

  Future<void> updateProjectStatus(
      String clientId, String projectId, String status) async {
    final client = findClient(clientId);
    if (client == null) return;
    final project = _findProject(client, projectId);
    if (project == null) return;
    project.status = status;
    await _persist();
  }

  Future<void> deleteProject(String clientId, String projectId) async {
    final client = findClient(clientId);
    if (client == null) return;
    client.projects.removeWhere((project) => project.id == projectId);
    await _persist();
  }

  List<({Project project, Client client})> get activeProjectsSorted {
    final result = <({Project project, Client client})>[];
    for (final client in _clients) {
      for (final project
          in client.projects.where((project) => project.status == 'active')) {
        result.add((project: project, client: client));
      }
    }
    result.sort((a, b) => a.project.deadline.compareTo(b.project.deadline));
    return result;
  }

  Future<void> addSession(
      String clientId, String projectId, WorkSession session) async {
    final client = findClient(clientId);
    if (client == null) return;
    final project = _findProject(client, projectId);
    if (project == null) return;
    project.sessions.add(session);
    project.recomputeLoggedHours();
    await _persist();
  }

  double get totalCollected => _clients
      .expand((client) => client.projects)
      .fold(0, (sum, project) => sum + project.upfront);

  double get totalOwed => _clients
      .expand((client) => client.projects)
      .fold(0, (sum, project) => sum + project.remaining);

  double get totalMrr => _clients
      .expand((client) => client.projects)
      .where((project) => project.maintenanceActive)
      .fold(0, (sum, project) => sum + project.maintenanceFee);

  int get todayMinutes => _clients
      .expand((client) => client.projects)
      .expand((project) => project.sessions)
      .where((session) => session.date == todayStr())
      .fold(0, (sum, session) => sum + session.durationMins);

  double get lifetimeValue => totalCollected + totalOwed + (totalMrr * 12);

  Project? _findProject(Client client, String projectId) {
    try {
      return client.projects.firstWhere((project) => project.id == projectId);
    } catch (_) {
      return null;
    }
  }
}
