import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../core/providers.dart';
import '../settings/subscription.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
    (ref) => ProfileRepository(ref.read(dashboardClientProvider)));

/// Gói cước suy ra từ JWT (claim subscription_tier/is_superuser) — hoạt động
/// không cần backend Phase B. Trả 'basic' nếu chưa có token.
final subscriptionTierProvider = FutureProvider<String>((ref) async {
  final token = await ref.read(tokenStoreProvider).accessToken;
  return resolveTier(token);
});

final activeChildStoreProvider =
    Provider<ActiveChildStore>((ref) => ActiveChildStore());

final parentProfileProvider = FutureProvider<ParentProfile>(
    (ref) => ref.read(profileRepositoryProvider).getParent());

final usageTodayProvider = FutureProvider<UsageToday>(
    (ref) => ref.read(profileRepositoryProvider).getUsageToday());

final childrenProvider = FutureProvider<List<ChildProfile>>(
    (ref) => ref.read(profileRepositoryProvider).getChildren());

final childDetailProvider = FutureProvider.family<ChildProfile, String>(
    (ref, id) => ref.read(profileRepositoryProvider).getChild(id));

/// Bé active hiện tại (đọc từ store). Ghi qua [setActiveChild].
final activeChildProvider = FutureProvider<ActiveChild?>(
    (ref) => ref.read(activeChildStoreProvider).read());

Future<void> setActiveChild(WidgetRef ref, ChildProfile c) async {
  await ref.read(activeChildStoreProvider).save(ActiveChild(
        childId: c.id,
        username: c.username,
        fullName: c.fullName,
      ));
  ref.invalidate(activeChildProvider);
}
