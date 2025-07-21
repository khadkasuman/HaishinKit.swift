import AVFoundation
import AVKit
import Foundation
import HaishinKit
import RTMPHaishinKit
import UIKit

final class PlaybackViewController: UIViewController {
    @IBOutlet private weak var playbackButton: UIButton!
    private var session: (any Session)?
    private let audioPlayer = AudioPlayer(audioEngine: AVAudioEngine())
    private var pictureInPictureController: AVPictureInPictureController?

    override func viewWillAppear(_ animated: Bool) {
        logger.info("viewWillAppear")
        super.viewWillAppear(animated)
        if #available(iOS 15.0, *), let layer = view.layer as? AVSampleBufferDisplayLayer, pictureInPictureController == nil {
            pictureInPictureController = AVPictureInPictureController(contentSource: .init(sampleBufferDisplayLayer: layer, playbackDelegate: self))
        }
        Task {
            do {
                session = try await SessionBuilderFactory.shared.make(Preference.default.makeURL()).build()
                if let session {
                    if let view = view as? (any StreamOutput) {
                        await session.stream.addOutput(view)
                    }
                    await session.stream.attachAudioPlayer(audioPlayer)
                }
            } catch {
                logger.error(error)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        logger.info("viewWillDisappear")
        super.viewWillDisappear(animated)
    }

    @IBAction func didEnterPixtureInPicture(_ button: UIButton) {
        pictureInPictureController?.startPictureInPicture()
    }

    @IBAction func didPlaybackButtonTap(_ button: UIButton) {
        Task {
            if button.isSelected {
                UIApplication.shared.isIdleTimerDisabled = false
                try? await session?.close()
                button.setTitle("●", for: [])
            } else {
                UIApplication.shared.isIdleTimerDisabled = true
                try? await session?.connect(.playback)
                button.setTitle("■", for: [])
            }
            button.isSelected.toggle()
        }
    }

    @objc
    private func didBecomeActive(_ notification: Notification) {
        logger.info(notification)
        if pictureInPictureController?.isPictureInPictureActive == false {
            Task {
                _ = try? await (session?.stream as? RTMPStream)?.receiveVideo(true)
            }
        }
    }

    @objc
    private func didEnterBackground(_ notification: Notification) {
        logger.info(notification)
        if pictureInPictureController?.isPictureInPictureActive == false {
            Task {
                _ = try? await (session?.stream as? RTMPStream)?.receiveVideo(false)
            }
        }
    }
}

extension PlaybackViewController: AVPictureInPictureSampleBufferPlaybackDelegate {
    // MARK: AVPictureInPictureControllerDelegate
    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
    }

    nonisolated func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: .zero, duration: .positiveInfinity)
    }

    nonisolated func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return false
    }

    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
    }

    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
