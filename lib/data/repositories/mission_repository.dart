import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mission.dart';
import '../models/mission_progress.dart';

abstract class MissionRepository {
  Future<List<Mission>> fetchMissions();
  Future<List<MissionProgress>> fetchUserProgress(String userId);
  Future<MissionProgress> completeMission({
    required String userId,
    required String missionId,
  });
}

class SupabaseMissionRepository implements MissionRepository {
  final SupabaseClient _client;
  SupabaseMissionRepository(this._client);

  @override
  Future<List<Mission>> fetchMissions() async {
    final rows = await _client
        .from('missions')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return (rows as List)
        .map((r) => Mission.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MissionProgress>> fetchUserProgress(String userId) async {
    final rows = await _client
        .from('user_mission_progress')
        .select()
        .eq('user_id', userId);
    return (rows as List)
        .map((r) => MissionProgress.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MissionProgress> completeMission({
    required String userId,
    required String missionId,
  }) async {
    final res = await _client.rpc(
      'complete_mission',
      params: {'p_mission_id': missionId},
    );
    final row = res as Map<String, dynamic>;
    return MissionProgress.fromJson(row);
  }
}
