//
//  SceneDelegate.swift
//  gbdisui
//
//  Created by Jeff Verkoeyen on 11/29/20.
//

import Combine
import UniformTypeIdentifiers
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  private var newProjectSubscriber: AnyCancellable?
  private var openRomSubscriber: AnyCancellable?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else {
      return
    }
    window = UIWindow(windowScene: windowScene)
//    windowScene.titlebar?

    window?.rootViewController = ProjectDocumentViewController()
    window?.makeKeyAndVisible()

    openRomSubscriber = NotificationCenter.default.publisher(for: .openRom)
      .receive(on: RunLoop.main)
      .sink(receiveValue: { [weak self] notification in
        guard let filetype = UTType(filenameExtension: "gb", conformingTo: .data) else {
          return
        }
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [filetype])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        self?.window?.rootViewController?.present(documentPicker, animated: true, completion: nil)
      })
  }

}

extension SceneDelegate: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else {
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      let data = try! Data(contentsOf: url)
//
//      let disassembly = LR35902.Disassembly(rom: data)
//      let files = try! disassembly.disassembleToFiles()
//
//      NotificationCenter.default.post(name: .disassembled, object: nil, userInfo: files)
    }
  }
}