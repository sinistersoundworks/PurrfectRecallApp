import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public enum MediaURL {
    public static func resolve(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }
        let base = APIConfig.baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let clean = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(base)/media/\(clean)")
    }
}

public struct CardMediaView: View {
    let card: FlashcardDTO
    let showAnswer: Bool
    @Bindable var audioPlayer: CardAudioPlayer

    public init(card: FlashcardDTO, showAnswer: Bool, audioPlayer: CardAudioPlayer) {
        self.card = card
        self.showAnswer = showAnswer
        self.audioPlayer = audioPlayer
    }

    public var body: some View {
        VStack(spacing: 16) {
            if let imageURL = MediaURL.resolve(card.imagePath) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    case .failure:
                        mediaPlaceholder(systemName: "photo", label: "Image unavailable")
                    default:
                        ProgressView()
                            .frame(height: 120)
                    }
                }
            }

            VStack(spacing: 8) {
                Text(card.question)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(BCColor.fg1)
                    .multilineTextAlignment(.center)

                if let ipa = card.ipa, !ipa.isEmpty {
                    Text(ipa)
                        .font(.title3)
                        .foregroundStyle(BCColor.fg2)
                }

                audioRow
            }

            if showAnswer {
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text(card.answer)
                        .font(.body)
                        .foregroundStyle(BCColor.colorInfo)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let example = card.example, !example.isEmpty {
                        Text(example)
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(BCColor.fg2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var audioRow: some View {
        HStack(spacing: 10) {
            if card.audioWord != nil {
                audioButton("Word", path: card.audioWord)
            }
            if showAnswer {
                if card.audioMeaning != nil {
                    audioButton("Meaning", path: card.audioMeaning)
                }
                if card.audioExample != nil {
                    audioButton("Example", path: card.audioExample)
                }
            }
        }
    }

    private func audioButton(_ label: String, path: String?) -> some View {
        Button {
            if let url = MediaURL.resolve(path) {
                audioPlayer.play(url: url)
            }
        } label: {
            Label(label, systemImage: "speaker.wave.2.fill")
                .font(.caption.weight(.medium))
        }
        .buttonStyle(.bordered)
        .disabled(path == nil)
    }

    private func mediaPlaceholder(systemName: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.largeTitle)
                .foregroundStyle(BCColor.fg3)
            Text(label)
                .font(.caption)
                .foregroundStyle(BCColor.fg3)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(BCColor.bgRaised)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
