import AVFoundation
import Foundation

@MainActor
@Observable
public final class CardAudioPlayer {
    private var player: AVPlayer?

    public init() {}

    public func play(url: URL) {
        stop()
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.play()
    }

    public func stop() {
        player?.pause()
        player = nil
    }
}
