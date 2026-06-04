#!/usr/bin/env swift

import Carbon
import Foundation

let desiredInputSourceIDs = [
  "com.apple.keylayout.Romanian-Standard"
]

func propertyString(_ source: TISInputSource, _ key: CFString) -> String {
  guard let rawValue = TISGetInputSourceProperty(source, key) else {
    return ""
  }

  return Unmanaged<CFString>.fromOpaque(rawValue).takeUnretainedValue() as String
}

func inputSource(withID id: String) -> TISInputSource? {
  let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
  guard let unmanagedMatches = TISCreateInputSourceList(filter, false) else {
    return nil
  }

  let matches = unmanagedMatches.takeRetainedValue() as NSArray
  guard let firstObject = matches.firstObject else {
    return nil
  }

  return (firstObject as! TISInputSource)
}

func inputSource(matching query: String) -> TISInputSource? {
  guard let unmanagedSources = TISCreateInputSourceList(nil, false) else {
    return nil
  }

  let sources = unmanagedSources.takeRetainedValue() as NSArray
  for case let source as TISInputSource in sources {
    let id = propertyString(source, kTISPropertyInputSourceID)
    let name = propertyString(source, kTISPropertyLocalizedName)
    if id.localizedCaseInsensitiveContains(query) || name.localizedCaseInsensitiveContains(query) {
      return source
    }
  }

  return nil
}

func writeError(_ message: String) {
  FileHandle.standardError.write(Data((message + "\n").utf8))
}

let previousInputSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue() as TISInputSource?

for id in desiredInputSourceIDs {
  guard let source = inputSource(withID: id) ?? inputSource(matching: "Romanian") else {
    writeError("Input source not found: \(id)")
    exit(1)
  }

  let enableStatus = TISEnableInputSource(source)
  if enableStatus != noErr {
    writeError("Failed to enable input source \(id): status \(enableStatus)")
    exit(1)
  }

  let selectStatus = TISSelectInputSource(source)
  if selectStatus != noErr {
    writeError("Failed to select input source \(id): status \(selectStatus)")
    exit(1)
  }

  print("Enabled input source: \(propertyString(source, kTISPropertyLocalizedName))")
}

if let previousInputSource {
  _ = TISSelectInputSource(previousInputSource)
}
