import AVFoundation
import SwiftUI
import UIKit

/// Which movements have a drawn coach clip, and how each clip should play.
enum CoachClips {
    /// Clips that repeat seamlessly for the whole step. Everything else plays once and holds its last frame.
    static let loops: Set<String> = [
        "cat-cow", "sun-flow-a", "march", "arm-circles", "hip-circles", "good-morning", "inchworm",
        "dead-bug", "bird-dog", "mountain-climber", "bridge-march", "russian-twist", "breathing",
    ]

    /// Only her clips exist so far; the Him toggle falls back to hers until his set is drawn.
    static func url(for movementID: String, coach: String) -> URL? {
        for name in ["\(coach)-\(movementID)", "her-\(movementID)"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "mp4") { return url }
        }
        return nil
    }

    static func poster(for movementID: String, coach: String) -> UIImage? {
        UIImage(named: "\(coach)-\(movementID)-end") ?? UIImage(named: "her-\(movementID)-end")
            ?? Bundle.main.path(forResource: "her-\(movementID)-end", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
    }
}

/// The coach area of the player: the drawn clip when there is one, the placeholder figure otherwise.
struct CoachStage: View {
    var movementID: String?
    var side: String?
    var resting: Bool
    var sessionID: String
    var paused: Bool

    private var coach: String { StudioSettings.shared.mascot }

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
            } else if let id = movementID, let url = CoachClips.url(for: id, coach: coach) {
                CoachVideo(url: url, loops: CoachClips.loops.contains(id), paused: paused)
                    .id("\(id)-\(side ?? "")")
                    .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            } else {
                MascotStage(movement: nil, sessionID: sessionID, resting: resting)
            }
        }
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
