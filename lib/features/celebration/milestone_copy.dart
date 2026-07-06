/// Per-milestone celebration copy (Design Spec §3.6).
class MilestoneCopy {
  const MilestoneCopy(this.title, this.message);
  final String title;
  final String message;
}

const Map<int, MilestoneCopy> kMilestoneCopy = {
  30: MilestoneCopy(
    'One Month Free',
    'The hardest stretch is behind you. Thirty days ago this felt impossible. '
        "Now it's simply who you are.",
  ),
  60: MilestoneCopy(
    'Sixty Days Strong',
    "This isn't willpower anymore, it's identity. "
        "You've rewired the reflex for good.",
  ),
  90: MilestoneCopy(
    'Ninety Days. Reborn.',
    "You didn't just break the habit, you outgrew it. "
        "The old you wouldn't recognize this discipline.",
  ),
};
