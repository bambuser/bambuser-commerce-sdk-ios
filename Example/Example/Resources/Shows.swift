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
        return URL(string: "https://svc-prod-us.liveshopping.bambuser.com/widgets/channels/pNxCZkolKbw35xwZOltt")!
    }

    static var organizationId: String {
        return "BdTubpTeJwzvYHljZiy4"
    }

    static var PlaylistConfig: BambuserShoppableVideoPlaylistInfo {
        BambuserShoppableVideoPlaylistInfo(
            orgId: organizationId,
            componentId: "mobile-sdk-tests"
        )
    }
}
