//
//  Shows.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-07-03.
//

import BambuserCommerceSDK
import Foundation

struct Show {
    enum ShowsWithId {
        case liveSimplePlayer
        case livePiP
        case liveFunctions
        case shoppableVideoSingleVideo

        var id: String {
            switch self {
            case .liveSimplePlayer:
                return "CYH7iy5x0q8sxe5gqita"
            case .livePiP:
                return "c45L9MgfpZDBx3WeGaWE"
            case .liveFunctions:
                return "c45L9MgfpZDBx3WeGaWE"
            case .shoppableVideoSingleVideo:
                return "puv_sxSLL9s5K16wDNZNuqVjvk"
            }
        }
    }

    static var PlaylistConfig: BambuserShoppableVideoPlaylistInfo {
        BambuserShoppableVideoPlaylistInfo(
            orgId: "BdTubpTeJwzvYHljZiy4",
            pageId: "mobile-home",
            playlistId: "best-sellers",
            title: "Best Sellers",
            packageName: "com.bambuser.commerce.sdk.demo"
        )
    }

    static var SkuConfig: BambuserShoppableVideoSkuInfo {
        BambuserShoppableVideoSkuInfo(
            orgId: "BdTubpTeJwzvYHljZiy4",
            sku: "b7c5"
        )
    }
}

