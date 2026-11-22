import SwiftUI

/// One card on the journal timeline. Reflections show their insight and open it when tapped; journal entries show their full text and can be deleted.
struct JournalItemRow: View {
    let item: JournalItem

    /// Called when a reflection is tapped, to open the insight it belongs to.
    let onOpenReflection: (InsightReflection) -> Void

    /// Called when Delete is picked on a journal entry's menu.
    let onDeleteEntry: (JournalEntry) -> Void

    var body: some View {
        switch item {
        case .reflection(let insightReflection):
            let insight = insightReflection.savedInsight.insight
            Button {
                HapticManager.shared.triggerImpact()
                onOpenReflection(insightReflection)
            } label: {
                card(systemImage: insight.icon.systemName, title: insight.reminder, createdAt: item.createdAt, opensDetail: true) {
                    reflectionPreview(insightReflection.reflection.content)
                }
            }
            .buttonStyle(.plain)
        case .entry(let entry):
            card(systemImage: "pencil.line", title: "Journal entry", createdAt: item.createdAt, opensDetail: false, onDelete: { onDeleteEntry(entry) }) {
                Text(entry.text)
                    .foregroundStyle(.textPrimary.opacity(0.8))
                    .font(.system(size: 15))
            }
        }
    }

    /// The white card shared by both kinds: an icon and title, the time, then whatever was written or recorded.
    /// Passing `onDelete` adds a "…" menu with a Delete option.
    private func card<Preview: View>(
        systemImage: String,
        title: String,
        createdAt: Date,
        opensDetail: Bool,
        onDelete: (() -> Void)? = nil,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .foregroundStyle(.appGreen)
                    Text(title)
                        .foregroundStyle(.textPrimary)
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text(createdAt.formatted(date: .omitted, time: .shortened))
                        .foregroundStyle(.textPrimary.opacity(0.5))
                        .font(.system(size: 13, weight: .medium))

                    if let onDelete {
                        Menu {
                            Button("Delete Entry", systemImage: "trash", role: .destructive, action: onDelete)
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(.textPrimary.opacity(0.6))
                                .frame(width: 32, height: 24)
                                .contentShape(.rect)
                        }
                        .accessibilityLabel("Entry options")
                    }
                }

                preview()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }

            if opensDetail {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundStyle(.textPrimary.opacity(0.5))
            }
        }
        .padding()
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .contentShape(.rect)
    }

    /// Typed reflections show their first few lines; voice ones show their length.
    @ViewBuilder
    private func reflectionPreview(_ content: ReflectionContent) -> some View {
        switch content {
        case .text(let text):
            Text(text)
                .foregroundStyle(.textPrimary.opacity(0.8))
                .font(.system(size: 15))
                .lineLimit(3)
        case .voice(let clip):
            Label {
                Text("Voice reflection · \(Duration.seconds(clip.duration).formatted(.time(pattern: .minuteSecond)))")
            } icon: {
                Image(systemName: "waveform")
            }
            .foregroundStyle(.textPrimary.opacity(0.8))
            .font(.system(size: 15))
        }
    }
}

#Preview {
    let savedInsight = SavedInsight(id: "1", insight: Insight(reminder: "Slow down", body: "", reflectionPrompt: "", icon: .calm))
    VStack(spacing: 12) {
        JournalItemRow(
            item: .entry(JournalEntry(id: "c", text: "Long day at work, but dinner with friends made up for it.", createdAt: .now)),
            onOpenReflection: { _ in },
            onDeleteEntry: { _ in }
        )
        JournalItemRow(
            item: .reflection(InsightReflection(
                reflection: Reflection(id: "a", content: .text("I took a long walk after lunch and didn't check my phone once."), createdAt: .now, treeSlot: 0, waterPoints: 10),
                savedInsight: savedInsight
            )),
            onOpenReflection: { _ in },
            onDeleteEntry: { _ in }
        )
        JournalItemRow(
            item: .reflection(InsightReflection(
                reflection: Reflection(id: "b", content: .voice(VoiceClip(audioPath: "", duration: 42, waveform: [])), createdAt: .now, treeSlot: 1, waterPoints: 10),
                savedInsight: savedInsight
            )),
            onOpenReflection: { _ in },
            onDeleteEntry: { _ in }
        )
    }
    .padding()
    .background(.appBackground)
}
