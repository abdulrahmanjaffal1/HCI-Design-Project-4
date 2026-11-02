import SwiftUI
import UIKit

/// The lock screen shown whenever the open hour is over.
/// Social is only open for one hour a day, at the same time for everyone.
struct ClosedView: View {
    @Environment(FeedStore.self) private var store

    var body: some View {
        let nextOpen = Self.nextOpenHour(after: Date())
        let day = Calendar.current.isDateInToday(nextOpen) ? "today" : "tomorrow"

        VStack(spacing: 0) {
            AppHeader()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .strokeBorder(Theme.border)
                        .frame(width: 118, height: 118)
                    Circle()
                        .fill(Theme.tint)
                        .frame(width: 92, height: 92)
                    Image(systemName: "lock")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Theme.green)
                }
                .padding(.top, 24)

                Text("Time for a pause.")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(Theme.text)

                Text("Social is open for one hour a day. Your feed, posts and profile reopen \(day) at 2:00 PM.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 4) {
                    Text("Next open hour")
                        .font(.caption)
                        .foregroundStyle(Theme.secondary)
                    Text(SampleData.openHour)
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Theme.text)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(Self.countdown(from: context.date, to: nextOpen))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .card()

                Text("Read a chapter or take a short walk. Nobody is posting until then, so there's nothing to miss.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .card()
            }
            .padding(.horizontal, 20)

            Spacer()

            // The real app can't be reopened early. This exists only so the demo can continue.
            Button("Prototype only: reopen app") { store.reopenForDemo() }
                .font(.footnote)
                .foregroundStyle(Theme.secondary)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    static func nextOpenHour(after date: Date) -> Date {
        Calendar.current.nextDate(
            after: date,
            matching: DateComponents(hour: SampleData.openHourStart, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? date.addingTimeInterval(24 * 60 * 60)
    }

    static func countdown(from now: Date, to target: Date) -> String {
        let seconds = max(0, Int(target.timeIntervalSince(now)))
        return String(format: "Opens in %d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}

/// Placeholder for tabs that are built after the progress check.
struct ComingSoonView: View {
    let title: String
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 0) {
            AppHeader()
            Spacer()
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.tint).frame(width: 84, height: 84)
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.green)
                }
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
                    .multilineTextAlignment(.center)
                Text("COMING NEXT")
                    .font(.caption2.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.tint, in: Capsule())
            }
            .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.background)
    }
}

/// Keeps the swipe-from-left-edge "back" gesture working even though
/// the app hides the standard navigation bar to match the Figma design.
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
