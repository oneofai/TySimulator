//
//  MainMenuController.swift
//  TySimulator
//
//  Created by luckytianyiyan on 2016/11/13.
//  Copyright © 2016年 luckytianyiyan. All rights reserved.
//

import Cocoa

class MainMenuController: NSObject {
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let quitMenuItem: NSMenuItem = NSMenuItem(title: NSLocalizedString("menu.quit", comment: "menu"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    let aboutItem: NSMenuItem = NSMenuItem(title: NSLocalizedString("menu.about", comment: "menu"), action: #selector(NSApplication.showAboutWindow), keyEquivalent: "")
    let preferenceItem: NSMenuItem = NSMenuItem(title: NSLocalizedString("menu.preference", comment: "menu"), action: #selector(NSApplication.showPreferencesWindow), keyEquivalent: ",")
    
    var devices: [DeviceModel] = []
    var deviceItems: [NSMenuItem] = []
    var recentItems: [NSMenuItem] = []
    
    var tagMap: [String: Int] = [:]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let icon = NSImage(named: "MenuIcon")
        icon?.isTemplate = true
        statusItem.image = icon
        
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(preferenceItem)
        menu.addItem(aboutItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitMenuItem)
        statusItem.menu = menu
        updateRecentAppMenus()
        updateDeviceMenus()
        
        NotificationCenter.default.addObserver(self, selector: #selector(devicesChangedNotification), name: Notification.Name.Device.DidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bootedChangedNotification), name: Notification.Name.Device.Booted.DidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(recentAppsDidRecordNotification), name: Notification.Name.LRUCache.DidRecord, object: nil)
    }
    
    func updateDeviceMenus() {
        log.verbose("update devices")
        statusItem.menu?.removeItems(deviceItems)
        
        devices = Device.shared.devices
        log.info("load devices: \(devices.count)")
        
        tagMap.removeAll()
        for item in 0 ..< devices.count {
            tagMap[devices[item].udid] = item
        }
        
        deviceItems = NSMenuItem.deviceMenuItems(devices, tagMap)
        
        deviceItems.reversed().forEach { (item) in
            statusItem.menu?.insertItem(item, at: recentItems.count)
        }
    }
    
    func updateRecentAppMenus() {
        guard let menu = statusItem.menu else {
            return
        }
        menu.removeItems(recentItems)
        recentItems.removeAll()
        let datas = LRUCache.shared.datas
        guard datas.count > 0 else {
            return
        }
        var apps: [ApplicationModel] = []
        let bootedDevices = Device.shared.bootedDevices
        for bundleID in datas {
            for device in bootedDevices {
                if let app = device.application(bundleIdentifier: bundleID) {
                    apps.append(app)
                    break
                }
            }
        }
        
        guard apps.count > 0 else {
            return
        }
        
        log.verbose("update recent apps")
        let titleItem = NSMenuItem.sectionMenuItem(NSLocalizedString("menu.recent", comment: "menu"))
        
        var models: [ApplicationModel] = []
        for (idx, app) in apps.enumerated() {
            if idx > 2 {
                break
            }
            models.append(app)
        }
        
        let appItems = NSMenuItem.applicationMenuItems(models, style: .detail)
        for menuItem in appItems.reversed() {
            menu.insertItem(menuItem, at: 0)
        }
        menu.insertItem(titleItem, at: 0)
        recentItems = [titleItem] + appItems
    }
    
    func updateBootedDeviceMenus() {
        let bootedDevices = Device.shared.bootedDevices
        let bootedDeviceUDIDs = bootedDevices.map { (device) -> String in
            return device.udid
        }
        log.verbose("booted device udid: \(bootedDeviceUDIDs)")
        
        let bootedItemTags = bootedDeviceUDIDs.map { (udid) -> Int in
            return tagMap[udid]!
        }
        statusItem.menu?.items.forEach({ (item) in
            item.state = bootedItemTags.contains(item.tag) ? 1 : 0
        })
    }
    
    // MARK: Notification
    func devicesChangedNotification() {
        updateDeviceMenus()
    }
    
    func bootedChangedNotification() {
        updateBootedDeviceMenus()
        updateRecentAppMenus()
    }
    
    func recentAppsDidRecordNotification() {
        updateRecentAppMenus()
    }
}

extension MainMenuController: NSMenuDelegate {
    // MARK: - NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        Device.shared.updateDeivces()
    }
}
