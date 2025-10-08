//
//  Navigation.swift
//  Example
//
//  Created by Saeid Basirnia on 3/11/25.
//

import SwiftUI
import Foundation

enum Tab: Hashable, CaseIterable {
    case live
    case shoppableVideo
    case wishlist
    case cart
}

enum PushDestination: Hashable {
    case liveShow(String)
}

enum SheetDestination: Hashable, Identifiable {
    var id: String { String(reflecting: self) }
    case openWebPage(URL)
}

final class NavigationManager: ObservableObject {
    @Published var currentTab: Tab

    @Published private var pushStack: [Tab: [PushDestination]]
    @Published private var sheetStack: [Tab: SheetDestination?]

    private var popObservers: [UUID: (
        _ tab: Tab,
        _ oldPath: [PushDestination],
        _ newPath: [PushDestination]
    ) -> Void] = [:]

    init(initialTab: Tab = .live) {
        currentTab = initialTab

        var pushStackLocal: [Tab: [PushDestination]] = [:]
        var sheetStackLocal: [Tab: SheetDestination?] = [:]
        Tab.allCases.forEach { tab in
            pushStackLocal[tab] = []
            sheetStackLocal[tab] = nil
        }
        pushStack = pushStackLocal
        sheetStack = sheetStackLocal
    }

    func pathBinding(for tab: Tab) -> Binding<[PushDestination]> {
        Binding(
            get: { self.pushStack[tab] ?? [] },
            set: { newPath in
                let oldPath = self.pushStack[tab] ?? []
                self.pushStack[tab] = newPath
                if newPath.count < oldPath.count {
                    self.notifyPopObservers(tab: tab, oldPath: oldPath, newPath: newPath)
                }
                self.objectWillChange.send()
            }
        )
    }

    func sheetBinding(for tab: Tab) -> Binding<SheetDestination?> {
        Binding(
            get: { self.sheetStack[tab] ?? nil },
            set: {
                self.sheetStack[tab] = $0
                self.objectWillChange.send()
            }
        )
    }

    func push(_ destination: PushDestination, in tab: Tab? = nil) {
        let targetTab = tab ?? currentTab
        pushStack[targetTab, default: []].append(destination)
        objectWillChange.send()
    }

    func pop(in tab: Tab? = nil) {
        let targetTab = tab ?? currentTab
        guard var path = pushStack[targetTab], !path.isEmpty else { return }
        let old = path
        path.removeLast()
        pushStack[targetTab] = path
        notifyPopObservers(tab: targetTab, oldPath: old, newPath: path)
        objectWillChange.send()
    }

    func popToRoot(in tab: Tab? = nil) {
        let targetTab = tab ?? currentTab
        let old = pushStack[targetTab] ?? []
        guard !old.isEmpty else { return }
        pushStack[targetTab] = []
        notifyPopObservers(tab: targetTab, oldPath: old, newPath: [])
        objectWillChange.send()
    }

    func popTo(_ destination: PushDestination, in tab: Tab? = nil) {
        let targetTab = tab ?? currentTab
        guard let path = pushStack[targetTab], let idx = path.lastIndex(of: destination) else { return }
        let old = path
        let newPath = Array(path.prefix(through: idx))
        pushStack[targetTab] = newPath
        notifyPopObservers(tab: targetTab, oldPath: old, newPath: newPath)
        objectWillChange.send()
    }

    func present(sheet: SheetDestination, in tab: Tab? = nil) {
        let targetTab = tab ?? currentTab
        sheetStack[targetTab] = sheet
        objectWillChange.send()
    }

    func dismissSheet(in tab: Tab? = nil) {
        let targetTab = tab ?? currentTab
        guard sheetStack[targetTab] != nil else { return }
        sheetStack[targetTab] = nil
        objectWillChange.send()
    }

    func switchTo(_ tab: Tab) {
        currentTab = tab
    }

    func switchTo(_ tab: Tab, thenPush destination: PushDestination) {
        currentTab = tab
        push(destination, in: tab)
    }

    func switchTo(_ tab: Tab, thenPresent sheet: SheetDestination) {
        currentTab = tab
        present(sheet: sheet, in: tab)
    }

    func isPushStackEmpty(_ tab: Tab) -> Bool {
        (pushStack[tab] ?? []).isEmpty
    }

    @discardableResult
    func addPopObserver(
        _ handler: @escaping (
            _ tab: Tab,
            _ oldPath: [PushDestination],
            _ newPath: [PushDestination]
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

    private func notifyPopObservers(
        tab: Tab,
        oldPath: [PushDestination],
        newPath: [PushDestination]
    ) {
        guard newPath.count < oldPath.count else { return }
        for h in popObservers.values { h(tab, oldPath, newPath) }
    }
}
