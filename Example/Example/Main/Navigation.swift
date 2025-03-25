//
//  Navigation.swift
//  Example
//
//  Created by Saeid Basirnia on 3/11/25.
//

import Combine
import Foundation

enum Destination: Hashable {
    case initializingShow
    case eventHandling
    case productHydration
    case productDetail(Product)
}

final class NavigationManager: ObservableObject {
    @Published var path: [Destination] = [] {
        didSet {
            if path.count < oldValue.count {
                notifyPopObservers(oldPath: oldValue, newPath: path)
            }
        }
    }

    private var popObservers: [UUID: (_ oldPath: [Destination], _ newPath: [Destination]) -> Void] = [:]

    func addPopObserver(
        _ handler: @escaping (
            _ oldPath: [Destination],
            _ newPath: [Destination]
        ) -> Void
    ) -> UUID {
        let id = UUID()
        popObservers[id] = handler
        return id
    }

    func removePopObserver(_ id: UUID?) {
        guard let id else { return }
        popObservers.removeValue(forKey: id)
    }

    private func notifyPopObservers(oldPath: [Destination], newPath: [Destination]) {
        for handler in popObservers.values {
            handler(oldPath, newPath)
        }
    }

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path.removeAll()
    }
}
