//
//  CommandViewController.swift
//  TySimulator
//
//  Created by luckytianyiyan on 2016/11/21.
//  Copyright © 2016年 luckytianyiyan. All rights reserved.
//

import Cocoa
import MASShortcut
import ACEViewSwift

class CommandViewController: NSViewController, ACEViewDelegate {
    var command: CommandModel!
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var shortcutView: MASShortcutView!
    @IBOutlet weak var aceView: ACEView!
    var save: ((CommandModel) -> Void)?
    
    init(_ command: CommandModel) {
        super.init(nibName: nil, bundle: nil)!
        self.command = command
    }
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        command = CommandModel()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Command Editor"
        nameTextField.bind("value", to: command, withKeyPath: #keyPath(CommandModel.name), options: [NSContinuouslyUpdatesValueBindingOption: true])
        shortcutView.bind("shortcutValue", to: command, withKeyPath: #keyPath(CommandModel.key), options: [NSContinuouslyUpdatesValueBindingOption: true])
        
        aceView.onReady = { [unowned self] in
            self.aceView.bind("string", to: self.command, withKeyPath: #keyPath(CommandModel.script), options: [NSContinuouslyUpdatesValueBindingOption: true])
            self.aceView.delegate = self
            if self.command.script.isEmpty {
                let (deviceIdentifier, applicationIdentifier) = self.placeholderDevice()
                self.aceView.string = "open " + Script.transformedValue(deviceIdentifier: deviceIdentifier, applicationIdentifier: applicationIdentifier)
            } else {
                self.aceView.string = self.command.script
            }
            self.aceView.mode = .sh
            self.aceView.theme = .xcode
            self.aceView.keyboardHandler = .ace
            self.aceView.showPrintMargin = false
            self.aceView.showInvisibles = true
            self.aceView.basicAutoCompletion = true
            self.aceView.liveAutocompletion = true
            self.aceView.snippets = true
            self.aceView.emmet = true
        }
    }
    
    func placeholderDevice() -> (String, String) {
        var deviceIdentifier = "booted"
        
        // try booted device
        if let device = Device.shared.bootedDevices.first {
            if device.applications.count > 0 {
                return (deviceIdentifier, (device.applications.first?.bundleIdentifier)!)
            }
        }
        
        // try other device
        for it in Device.shared.devices {
            deviceIdentifier = it.udid
            if it.applications.count > 0 {
                return (deviceIdentifier, (it.applications.first?.bundleIdentifier)!)
            }
        }
        return (deviceIdentifier, "your_app_bundle_identifier")
    }
    
    @IBAction func onSaveButtonClicked(_ sender: NSButton) {
        // TODO: log
        save?(command)
        dismiss(self)
    }
    
    @IBAction func onCancelButtonClicked(_ sender: NSButton) {
        // TODO: log
        dismiss(self)
    }
    
    // MARK: ACEViewDelegate
    func textDidChange(_ notification: Notification) {
        command.script = aceView.string
    }
}
