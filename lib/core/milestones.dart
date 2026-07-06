// Milestone configuration and the success-rate formula, isolated so they are
// a one-line change later (SRS §7).

/// Day thresholds that trigger a full-screen celebration (SRS §4 / FR-4).
const List<int> kMilestones = [30, 60, 90];

enum MilestoneState { reached, next, locked }

/// State of a milestone given the current whole-day streak.
MilestoneState milestoneStateFor(int threshold, int days) {
  if (days >= threshold) return MilestoneState.reached;
  final next = kMilestones.firstWhere((m) => days < m, orElse: () => -1);
  return threshold == next ? MilestoneState.next : MilestoneState.locked;
}

/// The next un-reached milestone, or null once all are cleared.
int? nextMilestone(int days) {
  for (final m in kMilestones) {
    if (days < m) return m;
  }
  return null;
}

/// Success-rate heuristic (SRS §4.6): start at 100, subtract 3 per relapse,
/// floored at 40. Intentionally simple; swap here to change the model.
int successRateAfterRelapse(int current) => (current - 3).clamp(40, 100);
