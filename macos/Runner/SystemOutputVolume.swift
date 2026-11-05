import CoreAudio
import Foundation

struct SystemOutputVolumeState {
  let volume: Double
  let muted: Bool
  let available: Bool

  var dictionary: [String: Any] {
    ["volume": volume, "muted": muted, "available": available]
  }
}

enum SystemOutputVolumeError: Error {
  case unavailable
  case coreAudio(OSStatus)
}

final class SystemOutputVolume {
  private struct Listener {
    let object: AudioObjectID
    var address: AudioObjectPropertyAddress
    let block: AudioObjectPropertyListenerBlock
  }

  private var device = AudioDeviceID(kAudioObjectUnknown)
  private var volumeElements: [AudioObjectPropertyElement] = []
  private var muteElements: [AudioObjectPropertyElement] = []
  private var channelRatios: [Float32] = []
  private var listeners: [Listener] = []
  private var onChange: ((SystemOutputVolumeState) -> Void)?

  var state: SystemOutputVolumeState {
    refreshDevice()
    let levels = volumeElements.compactMap { readFloat(kAudioDevicePropertyVolumeScalar, $0) }
    if levels.count == volumeElements.count, let maximum = levels.max(), maximum > 0 {
      channelRatios = levels.map { $0 / maximum }
    }
    let muteFlags = muteElements.compactMap { readUInt(kAudioDevicePropertyMute, $0) }
    return SystemOutputVolumeState(
      volume: Double(levels.max() ?? 0),
      muted: !muteFlags.isEmpty && muteFlags.allSatisfy { $0 != 0 },
      available: !levels.isEmpty && levels.count == volumeElements.count &&
        volumeElements.allSatisfy { isSettable(kAudioDevicePropertyVolumeScalar, $0) })
  }

  func startObserving(_ callback: @escaping (SystemOutputVolumeState) -> Void) {
    stopObserving()
    onChange = callback
    addListener(AudioObjectID(kAudioObjectSystemObject),
                AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                           mScope: kAudioObjectPropertyScopeGlobal,
                                           mElement: kAudioObjectPropertyElementMain)) { [weak self] in
      self?.publish()
    }
    // 이미 조회한 장치도 변경 알림을 다시 등록한다.
    bindDevice(defaultDevice())
    publish()
  }

  func stopObserving() {
    for var listener in listeners {
      AudioObjectRemovePropertyListenerBlock(listener.object, &listener.address, .main, listener.block)
    }
    listeners.removeAll()
    onChange = nil
  }

  func setVolume(_ requested: Double) throws -> SystemOutputVolumeState {
    guard state.available else { throw SystemOutputVolumeError.unavailable }
    let level = Float32(min(1, max(0, requested)))
    let previous = volumeElements.compactMap { readFloat(kAudioDevicePropertyVolumeScalar, $0) }
    guard previous.count == volumeElements.count else { throw SystemOutputVolumeError.unavailable }
    let maximum = previous.max() ?? 0
    let ratios = maximum > 0 ? previous.map { $0 / maximum } :
      (channelRatios.count == previous.count ? channelRatios : previous.map { _ in Float32(1) })

    // 메인 볼륨이 없는 장치는 좌우 채널의 기존 밸런스를 유지한다.
    for (index, element) in volumeElements.enumerated() {
      var value = ratios[index] * level
      var address = outputAddress(kAudioDevicePropertyVolumeScalar, element)
      let status = AudioObjectSetPropertyData(device, &address, 0, nil,
                                             UInt32(MemoryLayout<Float32>.size), &value)
      if status != noErr {
        for (restoreIndex, restoreElement) in volumeElements.enumerated() {
          var old = previous[restoreIndex]
          var restore = outputAddress(kAudioDevicePropertyVolumeScalar, restoreElement)
          AudioObjectSetPropertyData(device, &restore, 0, nil,
                                     UInt32(MemoryLayout<Float32>.size), &old)
        }
        throw SystemOutputVolumeError.coreAudio(status)
      }
    }
    for element in muteElements where isSettable(kAudioDevicePropertyMute, element) {
      var muted: UInt32 = level == 0 ? 1 : 0
      var address = outputAddress(kAudioDevicePropertyMute, element)
      let status = AudioObjectSetPropertyData(device, &address, 0, nil,
                                             UInt32(MemoryLayout<UInt32>.size), &muted)
      if status != noErr { throw SystemOutputVolumeError.coreAudio(status) }
    }
    return state
  }

  private func defaultDevice() -> AudioDeviceID {
    var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                            mScope: kAudioObjectPropertyScopeGlobal,
                                            mElement: kAudioObjectPropertyElementMain)
    var value = AudioDeviceID(kAudioObjectUnknown)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address,
                                           0, nil, &size, &value)
    return status == noErr ? value : AudioDeviceID(kAudioObjectUnknown)
  }

  private func refreshDevice() {
    let current = defaultDevice()
    if current != device { bindDevice(current) }
  }

  private func bindDevice(_ current: AudioDeviceID) {
    let hardware = AudioObjectID(kAudioObjectSystemObject)
    for var listener in listeners where listener.object != hardware {
      AudioObjectRemovePropertyListenerBlock(listener.object, &listener.address, .main, listener.block)
    }
    listeners.removeAll { $0.object != hardware }
    device = current
    volumeElements = []
    muteElements = []
    channelRatios = []
    guard device != kAudioObjectUnknown else { return }

    var stereo: [UInt32] = [1, 2]
    var size = UInt32(MemoryLayout<UInt32>.size * stereo.count)
    var stereoAddress = outputAddress(kAudioDevicePropertyPreferredChannelsForStereo, 0)
    _ = stereo.withUnsafeMutableBufferPointer { buffer in
      AudioObjectGetPropertyData(device, &stereoAddress, 0, nil, &size, buffer.baseAddress!)
    }
    let channels = Array(Set(stereo)).sorted()
    volumeElements = readFloat(kAudioDevicePropertyVolumeScalar, 0) != nil
      ? [0] : channels.filter { readFloat(kAudioDevicePropertyVolumeScalar, $0) != nil }
    muteElements = readUInt(kAudioDevicePropertyMute, 0) != nil
      ? [0] : channels.filter { readUInt(kAudioDevicePropertyMute, $0) != nil }

    guard onChange != nil else { return }
    for (selector, elements) in [(kAudioDevicePropertyVolumeScalar, volumeElements),
                                 (kAudioDevicePropertyMute, muteElements)] {
      for element in elements {
        addListener(device, outputAddress(selector, element)) { [weak self] in self?.publish() }
      }
    }
  }

  private func publish() { onChange?(state) }

  private func addListener(_ object: AudioObjectID, _ property: AudioObjectPropertyAddress,
                           _ changed: @escaping () -> Void) {
    var address = property
    let block: AudioObjectPropertyListenerBlock = { _, _ in changed() }
    if AudioObjectAddPropertyListenerBlock(object, &address, .main, block) == noErr {
      listeners.append(Listener(object: object, address: address, block: block))
    }
  }

  private func outputAddress(_ selector: AudioObjectPropertySelector,
                             _ element: AudioObjectPropertyElement) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioDevicePropertyScopeOutput,
                               mElement: element)
  }

  private func isSettable(_ selector: AudioObjectPropertySelector,
                          _ element: AudioObjectPropertyElement) -> Bool {
    var address = outputAddress(selector, element)
    var writable = DarwinBoolean(false)
    return AudioObjectIsPropertySettable(device, &address, &writable) == noErr && writable.boolValue
  }

  private func readFloat(_ selector: AudioObjectPropertySelector,
                         _ element: AudioObjectPropertyElement) -> Float32? {
    var address = outputAddress(selector, element)
    var value: Float32 = 0
    var size = UInt32(MemoryLayout<Float32>.size)
    guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr,
          value.isFinite else { return nil }
    return min(1, max(0, value))
  }

  private func readUInt(_ selector: AudioObjectPropertySelector,
                        _ element: AudioObjectPropertyElement) -> UInt32? {
    var address = outputAddress(selector, element)
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    return AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr ? value : nil
  }
}
