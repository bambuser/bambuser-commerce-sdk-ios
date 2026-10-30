//
//  ShoppableVideoConfigs.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import BambuserCommerceSDK

enum ShoppableVideoConfigs {
    static func reels() -> BambuserShoppableVideoConfiguration {
        make(
            thumbnail: [
                "enabled": false,
                "showPlayButton": false,
                "contentMode": "scaleAspectFill",
                "preview": nil,
                "showLoadingIndicator": true
            ],
            closedCaptions: "original",
            settings: "products:true; title:false; actions:true; productCardMode: thumbnail; autoplay:false",
            dismiss: "none"
        )
    }

    static func carousel() -> BambuserShoppableVideoConfiguration {
        make(
            thumbnail: thumbnail(showPlayButton: false),
            closedCaptions: "off",
            settings: "products:false; title:false; actions:false; productCardMode: thumbnail; autoplay:true",
            dismiss: "event"
        )
    }

    static func grid() -> BambuserShoppableVideoConfiguration {
        make(
            thumbnail: thumbnail(showPlayButton: true),
            closedCaptions: "off",
            settings: "products:true; title:false; actions:true; productCardMode: thumbnail; autoplay:false",
            dismiss: "event"
        )
    }

    static func spotlight() -> BambuserShoppableVideoConfiguration {
        make(
            thumbnail: thumbnail(showPlayButton: false),
            closedCaptions: "off",
            settings: "products:true; title:true; actions:true; productCardMode: thumbnail; autoplay:false",
            dismiss: "none"
        )
    }

    static func stories() -> BambuserShoppableVideoConfiguration {
        make(
            thumbnail: thumbnail(showPlayButton: false),
            closedCaptions: "original",
            settings: "products:true; title:false; actions:true; productCardMode: thumbnail; autoplay:false",
            dismiss: "none",
            ui: [
                "hideVolumeButton": true,
                "hideClosedCaptionsButton": true
            ]
        )
    }

    /// Layout and focus mode come from the Bam Hub appearance of the playlist.
    static func appearance() -> BambuserShoppableVideoConfiguration {
        BambuserShoppableVideoConfiguration(
            type: .playlist(Show.PlaylistConfig),
            events: ["*"],
            configuration: [
                "thumbnail": ["enabled": false],
                "playerConfig": [
                    "buttons": ["dismiss": "event"],
                    "currency": "SEK",
                    "locale": "en-US"
                ]
            ],
            videoScaleMode: .fill
        )
    }

    static func fab() -> BambuserShoppableVideoConfiguration {
        BambuserShoppableVideoConfiguration(
            type: .playlist(Show.FABPlaylistConfig),
            events: ["*"],
            configuration: [
                "preload": true,
                "thumbnail": ["enabled": false],
                "playerConfig": [
                    "buttons": ["dismiss": "event"],
                    "enableTrackingPoint": false,
                    "currency": "SEK",
                    "locale": "en-US"
                ]
            ],
            videoScaleMode: .fill
        )
    }

    private static func thumbnail(showPlayButton: Bool) -> [String: Sendable] {
        [
            "enabled": true,
            "showPlayButton": showPlayButton,
            "contentMode": "scaleAspectFill",
            "showLoadingIndicator": true
        ]
    }

    /// Every format plays the same playlist with the same currency and locale.
    /// They differ in the thumbnail, the preview settings and the dismiss button.
    private static func make(
        thumbnail: [String: Sendable],
        closedCaptions: String,
        settings: String,
        dismiss: String,
        ui: [String: Sendable]? = nil
    ) -> BambuserShoppableVideoConfiguration {
        var playerConfig: [String: Sendable] = [
            "buttons": ["dismiss": dismiss],
            "enableTrackingPoint": false,
            "currency": "SEK",
            "locale": "en-US"
        ]
        if let ui {
            playerConfig["ui"] = ui
        }
        return BambuserShoppableVideoConfiguration(
            type: .playlist(Show.PlaylistConfig),
            events: ["*"],
            configuration: [
                "preload": true,
                "thumbnail": thumbnail,
                "previewConfig": [
                    "productAction": "modal",
                    "closedCaptions": closedCaptions,
                    "settings": settings
                ],
                "playerConfig": playerConfig
            ],
            videoScaleMode: .fill
        )
    }
}
