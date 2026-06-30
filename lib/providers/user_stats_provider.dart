import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

// ── Achievement definition ────────────────────────────────────
class Achievement {
  final String id;
  final String emoji;
  final String titleKey;
  final String descKey;
  final bool unlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.emoji,
    required this.titleKey,
    required this.descKey,
    this.unlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({bool? unlocked, DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      emoji: emoji,
      titleKey: titleKey,
      descKey: descKey,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

// ── Podium result ─────────────────────────────────────────────
class BillRankResult {
  final String memberName;
  final double amount;
  final int rank; // 1, 2, 3

  const BillRankResult({
    required this.memberName,
    required this.amount,
    required this.rank,
  });
}

// ── All achievement definitions ───────────────────────────────
const _kAllAchievements = [
  Achievement(
    id: 'first_bill',
    emoji: '🎉',
    titleKey: 'achievement_first_bill',
    descKey: 'achievement_first_bill_desc',
  ),
  Achievement(
    id: 'bill_5',
    emoji: '🌿',
    titleKey: 'achievement_bill_5',
    descKey: 'achievement_bill_5_desc',
  ),
  Achievement(
    id: 'bill_10',
    emoji: '⚡',
    titleKey: 'achievement_bill_10',
    descKey: 'achievement_bill_10_desc',
  ),
  Achievement(
    id: 'bill_50',
    emoji: '👑',
    titleKey: 'achievement_bill_50',
    descKey: 'achievement_bill_50_desc',
  ),
  Achievement(
    id: 'gold_1',
    emoji: '🥇',
    titleKey: 'achievement_gold_1',
    descKey: 'achievement_gold_1_desc',
  ),
  Achievement(
    id: 'gold_5',
    emoji: '🏆',
    titleKey: 'achievement_gold_5',
    descKey: 'achievement_gold_5_desc',
  ),
  Achievement(
    id: 'big_spender',
    emoji: '💸',
    titleKey: 'achievement_big_spender',
    descKey: 'achievement_big_spender_desc',
  ),
];

// ── UserStatsProvider ─────────────────────────────────────────
/// Reads/writes gamification stats directly to the `profiles` table in Supabase.
/// Call [loadFromProfile] after auth loads the profile, and [recordBillCompleted]
/// when a bill is marked completed.
class UserStatsProvider extends ChangeNotifier {
  final _db = Supabase.instance.client;

  // ── In-memory state (mirrors DB) ──────────────────────────
  int _billsCompleted = 0;
  double _totalSpent = 0;
  int _goldMedals = 0;
  int _silverMedals = 0;
  int _bronzeMedals = 0;
  int _totalPoints = 0;
  Map<String, dynamic> _achievementsRaw = {};
  List<Achievement> _achievements = List.unmodifiable(_kAllAchievements);

  bool _loading = false;
  String? _userId;

  // ── Getters ────────────────────────────────────────────────
  int get billsCompleted => _billsCompleted;
  double get totalSpent => _totalSpent;
  int get goldMedals => _goldMedals;
  int get silverMedals => _silverMedals;
  int get bronzeMedals => _bronzeMedals;
  int get totalPoints => _totalPoints;
  bool get loading => _loading;
  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.unlocked).toList();

  // ── Load from Profile ──────────────────────────────────────
  /// Call this whenever the auth profile is loaded/refreshed.
  void loadFromProfile(Profile profile) {
    _userId = profile.id;
    _billsCompleted = profile.billsCompleted;
    _totalSpent = profile.totalSpent;
    _goldMedals = profile.goldMedals;
    _silverMedals = profile.silverMedals;
    _bronzeMedals = profile.bronzeMedals;
    _totalPoints = profile.totalPoints;
    _achievementsRaw = Map<String, dynamic>.from(profile.achievements);
    _rebuildAchievements();
    notifyListeners();
  }

  void _rebuildAchievements() {
    _achievements = List.unmodifiable(
      _kAllAchievements.map((a) {
        final raw = _achievementsRaw[a.id];
        if (raw is Map && raw['unlocked'] == true) {
          DateTime? dt;
          if (raw['unlockedAt'] is String) {
            dt = DateTime.tryParse(raw['unlockedAt'] as String);
          }
          return a.copyWith(unlocked: true, unlockedAt: dt);
        }
        return a;
      }).toList(),
    );
  }

  // ── Record Bill Completed ──────────────────────────────────
  /// Call when a bill is marked as completed.
  /// [memberAmounts] = map of memberName → amount they owe.
  /// [currentUserMemberName] = the name of the current user's bill_member (for rank).
  Future<List<String>> recordBillCompleted({
    required Map<String, double> memberAmounts,
    required double myAmount,
  }) async {
    if (_userId == null) return [];

    final podium = computePodium(memberAmounts);
    final myRank = podium.indexWhere(
      (r) => (r.amount - myAmount).abs() < 0.01,
    );

    int goldDelta = 0;
    int silverDelta = 0;
    int bronzeDelta = 0;
    int pointsDelta = 0;

    if (myRank == 0) {
      goldDelta = 1;
      pointsDelta = 30;
    } else if (myRank == 1) {
      silverDelta = 1;
      pointsDelta = 20;
    } else if (myRank == 2) {
      bronzeDelta = 1;
      pointsDelta = 10;
    }

    // Update local state optimistically
    _billsCompleted += 1;
    _totalSpent += myAmount;
    _goldMedals += goldDelta;
    _silverMedals += silverDelta;
    _bronzeMedals += bronzeDelta;
    _totalPoints += pointsDelta;

    // Check achievements
    final newlyUnlocked = <String>[];
    _checkAndUnlockAchievements(newlyUnlocked);

    // Achievement points
    final achPoints = newlyUnlocked.length * 50;
    _totalPoints += achPoints;
    pointsDelta += achPoints;

    notifyListeners();

    // Persist to Supabase
    try {
      await _db.from('profiles').update({
        'bills_completed': _billsCompleted,
        'total_spent': _totalSpent,
        'gold_medals': _goldMedals,
        'silver_medals': _silverMedals,
        'bronze_medals': _bronzeMedals,
        'total_points': _totalPoints,
        'achievements': _achievementsRaw,
      }).eq('id', _userId!);
    } catch (e) {
      debugPrint('UserStatsProvider: failed to persist stats: $e');
    }

    return newlyUnlocked;
  }

  void _checkAndUnlockAchievements(List<String> newlyUnlocked) {
    void tryUnlock(String id, bool condition) {
      if (!condition) return;
      if (_achievementsRaw[id]?['unlocked'] == true) return;
      _achievementsRaw[id] = {
        'unlocked': true,
        'unlockedAt': DateTime.now().toIso8601String(),
      };
      newlyUnlocked.add(id);
    }

    tryUnlock('first_bill', _billsCompleted >= 1);
    tryUnlock('bill_5', _billsCompleted >= 5);
    tryUnlock('bill_10', _billsCompleted >= 10);
    tryUnlock('bill_50', _billsCompleted >= 50);
    tryUnlock('gold_1', _goldMedals >= 1);
    tryUnlock('gold_5', _goldMedals >= 5);
    tryUnlock('big_spender', _totalSpent >= 10000);

    _rebuildAchievements();
  }

  // ── Save locale to DB ──────────────────────────────────────
  Future<void> saveLocale(String locale) async {
    if (_userId == null) return;
    try {
      await _db
          .from('profiles')
          .update({'locale': locale}).eq('id', _userId!);
    } catch (e) {
      debugPrint('UserStatsProvider: failed to save locale: $e');
    }
  }

  // ── Podium helper ──────────────────────────────────────────
  static List<BillRankResult> computePodium(Map<String, double> memberAmounts) {
    if (memberAmounts.isEmpty) return [];
    final sorted = memberAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final result = <BillRankResult>[];
    for (int i = 0; i < sorted.length && i < 3; i++) {
      result.add(BillRankResult(
        memberName: sorted[i].key,
        amount: sorted[i].value,
        rank: i + 1,
      ));
    }
    return result;
  }

  // ── Reset (on sign-out) ────────────────────────────────────
  void reset() {
    _userId = null;
    _billsCompleted = 0;
    _totalSpent = 0;
    _goldMedals = 0;
    _silverMedals = 0;
    _bronzeMedals = 0;
    _totalPoints = 0;
    _achievementsRaw = {};
    _achievements = List.unmodifiable(_kAllAchievements);
    notifyListeners();
  }
}
