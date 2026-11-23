import AVFoundation
import RepBellEngine
import SwiftUI
import UIKit

/// Which movements have a coach clip, and how each clip should play.
/// The clips are generated media: they are in TestFlight builds for testing while requirement R-1 is open
/// (decision of 23 Nov 2026), and `Features.coachMedia` switches them off.
enum CoachClips {
    /// Clips that repeat seamlessly for the whole step. Everything else plays once and holds its last frame.
    static let loops: Set<String> = [
        "cat-cow", "sun-flow-a", "march", "arm-circles", "hip-circles", "good-morning", "inchworm",
        "dead-bug", "bird-dog", "mountain-climber", "bridge-march", "russian-twist", "breathing",
    ]

    /// The chosen coach's clip, falling back to the other coach's when only one exists.
    static func url(for movementID: String, coach: String) -> URL? {
        guard Features.coachMedia else { return nil }
        for name in ["\(coach)-\(movementID)", "her-\(movementID)", "him-\(movementID)"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "mp4") { return url }
        }
        return nil
    }

    static func poster(for movementID: String, coach: String) -> UIImage? {
        guard Features.coachMedia else { return nil }
        for name in ["\(coach)-\(movementID)-end", "her-\(movementID)-end", "him-\(movementID)-end"] {
            if let image = UIImage(named: name)
                ?? Bundle.main.path(forResource: name, ofType: "png").flatMap(UIImage.init(contentsOfFile:)) {
                return image
            }
        }
        return nil
    }

    static func has(_ movementID: String) -> Bool {
        url(for: movementID, coach: "her") != nil
    }
}

/// The coach area of the player: the coach clip when there is one, the line figure otherwise.
struct CoachStage: View {
    var movement: StudioMovement?
    var side: String?
    var resting: Bool
    var sessionID: String
    var paused: Bool

    private var coach: String { StudioSettings.shared.mascot }
    private var movementID: String? { movement?.id }

    var body: some View {
        let mirrored = side == "right"
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Chalk.ground)
            if let id = movementID, resting, let poster = CoachClips.poster(for: id, coach: coach) {
                // Rest: show the next move's finished pose, dimmed, so the person can get ready.
                Image(uiImage: poster)
                    .resizable()
                    .scaledToFit()
                    .opacity(0.45)
                    .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            } else if !resting, let id = movementID, let url = CoachClips.url(for: id, coach: coach) {
                CoachVideo(url: url, loops: CoachClips.loops.contains(id), paused: paused)
                    .id("\(url.lastPathComponent)-\(side ?? "")")
                    .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            } else {
                MascotStage(movement: movement, sessionID: sessionID, resting: resting)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityHidden(true)
    }
}

/// A coach clip on its own, for screens outside the Workouts player (the desk stretch).
/// While `playing` is false it shows the finished pose, still.
struct CoachClipView: View {
    var movementID: String
    var playing: Bool
    var mirrored = false

    private var coach: String { StudioSettings.shared.mascot }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Chalk.ground)
            if playing, let url = CoachClips.url(for: movementID, coach: coach) {
                CoachVideo(url: url, loops: CoachClips.loops.contains(movementID), paused: false)
                    .id("\(url.lastPathComponent)-\(mirrored)")
            } else if let poster = CoachClips.poster(for: movementID, coach: coach) {
                Image(uiImage: poster).resizable().scaledToFit()
            }
        }
        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityHidden(true)
    }
}

private struct CoachVideo: UIViewRepresentable {
    var url: URL
    var loops: Bool
    var paused: Bool

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.configure(url: url, loops: loops)
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        view.setPaused(paused)
    }

    static func dismantleUIView(_ view: PlayerView, coordinator: ()) {
        view.stop()
    }
}

final class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    func configure(url: URL, loops: Bool) {
        backgroundColor = .clear
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        queue.isMuted = true
        queue.preventsDisplaySleepDuringVideoPlayback = false
        if loops {
            looper = AVPlayerLooper(player: queue, templateItem: item)
        } else {
            queue.insert(item, after: nil)
            queue.actionAtItemEnd = .pause
        }
        playerLayer.player = queue
        playerLayer.videoGravity = .resizeAspect
        player = queue
        queue.play()
    }

    func setPaused(_ paused: Bool) {
        guard let player else { return }
        if paused {
            player.pause()
        } else if player.rate == 0, let item = player.currentItem, item.currentTime() < item.duration {
            player.play()
        }
    }

    func stop() {
        player?.pause()
        looper?.disableLooping()
        looper = nil
        player = nil
        playerLayer.player = nil
    }
}
