//
//  Endpoint.swift
//  VisionHandPose
//
//  Created by Manish Parihar on 30.09.24.
//

/**
    This is a Future Scope
 **/

import Foundation

enum Endpoint {
    case oscHandGesture
}

extension Endpoint {
    var host: String { "192.168.1.100" }
    
    var path: String {
        switch self {
        case .oscHandGesture:
            return ":8000"
        }
    }
}

extension Endpoint {
    var url: URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = host
        urlComponents.path = path
        return urlComponents.url
    }
}
