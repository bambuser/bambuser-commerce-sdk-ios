//
//  ShoppableVideoConfigs.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import BambuserCommerceSDK

enum ShoppableVideoConfigs {
    static func reels() -> BambuserShoppableVideoConfiguration {
        BambuserShoppableVideoConfiguration(
            type: .playlist(Show.PlaylistConfig),
            events: ["*"],
            configuration: [
                "preload": true,
                "thumbnail": [
                    "enabled": false,
                    "showPlayButton": false,
                    "contentMode": "scaleAspectFill",
                    "preview": nil,
                    "showLoadingIndicator": true
                ],
                "previewConfig": [
                    "productAction": "modal",
                    "closedCaptions": "original",
                    "settings": "products:true; title:false; actions:true; productCardMode: thumbnail; autoplay:false"
                ],
                "playerConfig": [
                    "buttons": ["dismiss": "none"],
                    "enableTrackingPoint": false,
                    "currency": "SEK",
                    "locale": "en-US"
                ]
            ]
        )
    }

    static func carousel() -> BambuserShoppableVideoConfiguration {
        BambuserShoppableVideoConfiguration(
            type: .playlist(Show.PlaylistConfig),
            events: ["*"],
            configuration: [
                "preload": true,
                "thumbnail": [
                    "enabled": true,
                    "showPlayButton": false,
                    "contentMode": "scaleAspectFill",
                    "showLoadingIndicator": true
                ],
                "previewConfig": [
                    "productAction": "modal",
                    "closedCaptions": "off",
                    "settings": "products:false; title:false; actions:false; productCardMode: thumbnail; autoplay:true"
                ],
                "playerConfig": [
                    "buttons": ["dismiss": "event"],
                    "enableTrackingPoint": false,
                    "currency": "SEK",
                    "locale": "en-US"
                ]
            ]
        )
    }

    static func grid() -> BambuserShoppableVideoConfiguration {
        BambuserShoppableVideoConfiguration(
            type: .playlist(Show.PlaylistConfig),
            events: ["*"],
            configuration: [
                "preload": true,
                "thumbnail": [
                    "enabled": true,
                    "showPlayButton": true,
                    "contentMode": "scaleAspectFill",
                    "showLoadingIndicator": true
                ],
                "previewConfig": [
                    "productAction": "modal",
                    "closedCaptions": "off",
                    "settings": "products:true; title:false; actions:true; productCardMode: thumbnail; autoplay:false"
                ],
                "playerConfig": [
                    "buttons": ["dismiss": "event"],
                    "enableTrackingPoint": false,
                    "currency": "SEK",
                    "locale": "en-US"
                ]
            ]
        )
    }

    static func spotlight() -> BambuserShoppableVideoConfiguration {
        BambuserShoppableVideoConfiguration(
            type: .playlist(Show.PlaylistConfig),
            events: ["*"],
            configuration: [
                "preload": true,
                "thumbnail": [
                    "enabled": true,
                    "showPlayButton": false,
                    "contentMode": "scaleAspectFill",
                    "showLoadingIndicator": true
                ],
                "previewConfig": [
                    "productAction": "modal",
                    "closedCaptions": "off",
                    "settings": "products:true; title:true; actions:true; productCardMode: thumbnail; autoplay:false"
                ],
                "playerConfig": [
                    "buttons": ["dismiss": "none"],
                    "enableTrackingPoint": false,
                    "currency": "SEK",
                    "locale": "en-US"
                ]
            ]
        )
    }

    static func stories() -> BambuserShoppableVideoConfiguration {
        BambuserShoppableVideoConfiguration(
            type: .playlist(Show.PlaylistConfig),
            events: ["*"],
            configuration: [
                "preload": true,
                "thumbnail": [
                    "enabled": true,
                    "showPlayButton": false,
                    "contentMode": "scaleAspectFill",
                    "showLoadingIndicator": true
                ],
                "previewConfig": [
                    "productAction": "modal",
                    "closedCaptions": "original",
                    "settings": "products:true; title:false; actions:true; productCardMode: thumbnail; autoplay:false"
                ],
                "playerConfig": [
                    "buttons": ["dismiss": "none"],
                    "ui": [
                        "hideVolumeButton": true,
                        "hideClosedCaptionsButton": true
                    ],
                    "enableTrackingPoint": false,
                    "currency": "SEK",
                    "locale": "en-US"
                ]
            ]
        )
    }
}
