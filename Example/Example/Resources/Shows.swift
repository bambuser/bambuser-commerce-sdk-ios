//
//  Shows.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-07-03.
//

import BambuserCommerceSDK
import Foundation

struct Show {
    static var WidgetUrl: URL {
        URL(string: "https://svc-prod-us.liveshopping.bambuser.com/widgets/channels/pNxCZkolKbw35xwZOltt")!
    }

    static var PlaylistConfig: BambuserShoppableVideoPlaylistInfo {
        BambuserShoppableVideoPlaylistInfo(
            orgId: "BdTubpTeJwzvYHljZiy4",
            pageId: "mobile-home-screen",
            playlistId: "best-sellers",
            title: "Best Sellers",
            packageName: "com.bambuser.Example"
        )
    }
}

