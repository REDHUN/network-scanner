import Flutter
import Foundation
import Network
import Darwin

private final class ScanCancellationToken {
  private let lock = NSLock()
  private var cancelled = false

  var isCancelled: Bool {
    lock.lock()
    defer { lock.unlock() }
    return cancelled
  }

  func cancel() {
    lock.lock()
    cancelled = true
    lock.unlock()
  }
}

private struct LocalNetworkInfo {
  let ip: String
  let prefixLength: Int
  let subnet: String
  let gateway: String?
  let interfaceName: String
}

private enum TCPProbeResult {
  case open
  case responded
  case noResponse

  var hostIsReachable: Bool {
    switch self {
    case .open, .responded:
      return true
    case .noResponse:
      return false
    }
  }
}

public class FlutterNetworkScannerPlugin: NSObject, FlutterPlugin {
  private let stateLock = NSLock()
  private var attached = true
  private var activeTokens: [ScanCancellationToken] = []

  private let defaultPorts = [80, 443, 22, 21, 8080, 445, 53, 3389, 8008, 9100]
  private let discoveryPorts = [
    80, 443, 22, 445, 8080, 53, 8008, 62078, 9100, 3000, 5000, 7000, 7100, 8443,
  ]
  private let maxScanHosts: Int64 = 4_096
  private let maxScanDuration: DispatchTimeInterval = .seconds(20)

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_network_scanner",
      binaryMessenger: registrar.messenger()
    )
    let instance = FlutterNetworkScannerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getNetworkInfo":
      result(localNetworkInfoMap())

    case "scanNetwork":
      do {
        let arguments = call.arguments as? [String: Any]
        let timeout = try normalizedTimeout(arguments?["timeoutMs"], defaultValue: 250)
        let token = registerToken()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
          guard let self = self else { return }
          defer { self.unregisterToken(token) }
          do {
            let devices = try self.scanNetwork(timeoutMs: timeout, token: token)
            self.complete(result, value: devices)
          } catch {
            self.complete(
              result,
              value: FlutterError(code: "SCAN_ERROR", message: error.localizedDescription, details: nil)
            )
          }
        }
      } catch {
        result(FlutterError(code: "INVALID_ARGS", message: error.localizedDescription, details: nil))
      }

    case "pingHost":
      do {
        let arguments = call.arguments as? [String: Any]
        guard let ip = arguments?["ip"] as? String, !ip.isEmpty else {
          throw ScannerError.invalidArgument("IP cannot be null")
        }
        let timeout = try normalizedTimeout(arguments?["timeoutMs"], defaultValue: 500)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
          guard let self = self else { return }
          let started = DispatchTime.now().uptimeNanoseconds
          let reachable = self.discoveryPorts.contains {
            self.tcpProbe(ip: ip, port: $0, timeoutMs: timeout).hostIsReachable
          }
          let elapsed = reachable
            ? Int((DispatchTime.now().uptimeNanoseconds - started) / 1_000_000)
            : -1
          self.complete(result, value: elapsed)
        }
      } catch {
        result(FlutterError(code: "INVALID_ARGS", message: error.localizedDescription, details: nil))
      }

    case "scanPorts":
      do {
        let arguments = call.arguments as? [String: Any]
        guard let ip = arguments?["ip"] as? String, !ip.isEmpty else {
          throw ScannerError.invalidArgument("IP cannot be null")
        }
        let ports = try normalizedPorts(arguments?["ports"])
        let timeout = try normalizedTimeout(arguments?["timeoutMs"], defaultValue: 300)
        if ports.isEmpty {
          result([])
          return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
          guard let self = self else { return }
          let semaphore = DispatchSemaphore(value: min(32, ports.count))
          let group = DispatchGroup()
          let lock = NSLock()
          var openPorts: [Int] = []

          for port in ports {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
              semaphore.wait()
              defer {
                semaphore.signal()
                group.leave()
              }
              if self.tcpProbe(ip: ip, port: port, timeoutMs: timeout) == .open {
                lock.lock()
                openPorts.append(port)
                lock.unlock()
              }
            }
          }
          group.wait()
          self.complete(result, value: openPorts.sorted())
        }
      } catch {
        result(FlutterError(code: "INVALID_ARGS", message: error.localizedDescription, details: nil))
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    stateLock.lock()
    attached = false
    activeTokens.forEach { $0.cancel() }
    activeTokens.removeAll()
    stateLock.unlock()
  }

  private enum ScannerError: LocalizedError {
    case invalidArgument(String)
    case scanTooLarge(Int64)
    case cancelled

    var errorDescription: String? {
      switch self {
      case .invalidArgument(let message): return message
      case .scanTooLarge(let count):
        return "Active subnet contains \(count) hosts; refusing an unsafe scan (maximum 4096)"
      case .cancelled: return "Network scan was cancelled"
      }
    }
  }

  private func normalizedTimeout(_ value: Any?, defaultValue: Int) throws -> Int {
    guard let value = value else { return defaultValue }
    guard let number = value as? NSNumber,
          number.doubleValue.isFinite,
          number.doubleValue == floor(number.doubleValue) else {
      throw ScannerError.invalidArgument("timeoutMs must be an integer")
    }
    let timeout = number.intValue
    guard timeout >= 1, timeout <= 10_000 else {
      throw ScannerError.invalidArgument("timeoutMs must be between 1 and 10000 milliseconds")
    }
    return timeout
  }

  private func normalizedPorts(_ value: Any?) throws -> [Int] {
    guard let value = value else { return defaultPorts }
    guard let values = value as? [Any] else {
      throw ScannerError.invalidArgument("ports must be a list of integers")
    }
    var ports: [Int] = []
    for value in values {
      guard let number = value as? NSNumber,
            number.doubleValue.isFinite,
            number.doubleValue == floor(number.doubleValue) else {
        throw ScannerError.invalidArgument("ports must contain only integers")
      }
      let port = number.intValue
      guard port >= 1, port <= 65_535 else {
        throw ScannerError.invalidArgument("ports must be between 1 and 65535")
      }
      if !ports.contains(port) { ports.append(port) }
    }
    return ports
  }

  private func registerToken() -> ScanCancellationToken {
    let token = ScanCancellationToken()
    stateLock.lock()
    activeTokens.append(token)
    stateLock.unlock()
    return token
  }

  private func unregisterToken(_ token: ScanCancellationToken) {
    stateLock.lock()
    activeTokens.removeAll { $0 === token }
    stateLock.unlock()
  }

  private func isAttached() -> Bool {
    stateLock.lock()
    defer { stateLock.unlock() }
    return attached
  }

  private func complete(_ result: @escaping FlutterResult, value: Any?) {
    DispatchQueue.main.async { [weak self] in
      guard let self, self.isAttached() else { return }
      result(value)
    }
  }

  private func localNetworkInfo() -> LocalNetworkInfo? {
    var addresses: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&addresses) == 0, let first = addresses else { return nil }
    defer { freeifaddrs(addresses) }

    var candidates: [LocalNetworkInfo] = []
    var current: UnsafeMutablePointer<ifaddrs>? = first
    while let interface = current?.pointee {
      defer { current = interface.ifa_next }
      guard let addressPointer = interface.ifa_addr,
            let maskPointer = interface.ifa_netmask,
            addressPointer.pointee.sa_family == sa_family_t(AF_INET),
            (interface.ifa_flags & UInt32(IFF_UP)) != 0 else { continue }

      let name = String(cString: interface.ifa_name)
      if name == "lo0" || name.hasPrefix("utun") || name == "awdl0" { continue }
      let address = addressPointer.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
      let mask = maskPointer.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
      let ip = String(cString: inet_ntoa(address.sin_addr))
      let subnet = String(cString: inet_ntoa(mask.sin_addr))
      guard let ipValue = ipv4Value(ip), let prefix = subnetPrefix(subnet) else { continue }
       candidates.append(LocalNetworkInfo(
         ip: ip,
         prefixLength: prefix,
         subnet: subnet,
         gateway: nil,
        interfaceName: name
      ))
    }

    return candidates.sorted { lhs, rhs in
      (lhs.interfaceName == "en0" ? 0 : 1) < (rhs.interfaceName == "en0" ? 0 : 1)
    }.first
  }

  private func localNetworkInfoMap() -> [String: Any?]? {
    guard let info = localNetworkInfo() else { return nil }
    return [
      "ip": info.ip,
      "subnet": info.subnet,
      "gateway": info.gateway,
      "interface": info.interfaceName,
      "ssid": nil,
    ]
  }

  private func scanNetwork(timeoutMs: Int, token: ScanCancellationToken) throws -> [[String: Any?]] {
    guard let info = localNetworkInfo(),
          let localValue = ipv4Value(info.ip) else { return [] }
    let mask = prefixMask(info.prefixLength)
    let network = localValue & mask
    let broadcast = network | (~mask & 0xffff_ffff)
    let firstHost = info.prefixLength >= 31 ? network : network + 1
    let lastHost = info.prefixLength >= 31 ? broadcast : broadcast - 1
    guard lastHost >= firstHost else { return [] }
    let hostCount = lastHost - firstHost + 1
    guard hostCount <= maxScanHosts else { throw ScannerError.scanTooLarge(hostCount) }

    let semaphore = DispatchSemaphore(value: min(64, Int(hostCount)))
    let group = DispatchGroup()
    let lock = NSLock()
    var devices: [[String: Any?]] = []

    for value in firstHost...lastHost {
      group.enter()
      DispatchQueue.global(qos: .userInitiated).async {
        defer { group.leave() }
        semaphore.wait()
        defer { semaphore.signal() }
        guard !token.isCancelled else { return }
        let ip = self.ipv4String(value)
        let isCurrent = value == localValue
        let isGateway = ip == info.gateway
        var openPorts: [Int] = []
        var hostResponded = false
        var latency = isCurrent ? 1 : -1
        if !isCurrent {
          let started = DispatchTime.now().uptimeNanoseconds
          for port in self.discoveryPorts where !token.isCancelled {
            switch self.tcpProbe(ip: ip, port: port, timeoutMs: timeoutMs) {
            case .open:
              hostResponded = true
              openPorts.append(port)
              if latency < 0 {
                latency = Int((DispatchTime.now().uptimeNanoseconds - started) / 1_000_000)
              }
            case .responded:
              // A TCP refusal/reset still proves that the host is on the LAN even
              // though that particular service is closed. Do not drop phones,
              // tablets, or laptops that expose no tested listening port.
              hostResponded = true
              if latency < 0 {
                latency = Int((DispatchTime.now().uptimeNanoseconds - started) / 1_000_000)
              }
            case .noResponse:
              continue
            }
          }
        }
        guard isCurrent || isGateway || hostResponded else { return }
        let device: [String: Any?] = [
          "ip": ip,
          "hostname": nil,
          "openPorts": openPorts,
          "mac": nil,
          "vendor": nil,
          "pingMs": max(latency, 1),
          "deviceType": isGateway ? "router" : "generic",
          "isCurrentDevice": isCurrent,
          "isGateway": isGateway,
        ]
        lock.lock()
        devices.append(device)
        lock.unlock()
      }
    }
    if group.wait(timeout: .now() + maxScanDuration) == .timedOut {
       token.cancel()
       group.wait()
       throw ScannerError.cancelled
     }
    if token.isCancelled { throw ScannerError.cancelled }
    return devices.sorted { lhs, rhs in
      let lhsIp = (lhs["ip"] ?? nil) as? String ?? "0.0.0.0"
      let rhsIp = (rhs["ip"] ?? nil) as? String ?? "0.0.0.0"
      return (self.ipv4Value(lhsIp) ?? 0) < (self.ipv4Value(rhsIp) ?? 0)
    }
  }

  private func tcpProbe(ip: String, port: Int, timeoutMs: Int) -> TCPProbeResult {
    guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else { return .noResponse }
    let connection = NWConnection(host: NWEndpoint.Host(ip), port: nwPort, using: .tcp)
    let semaphore = DispatchSemaphore(value: 0)
    let lock = NSLock()
    var completed = false
    var probeResult: TCPProbeResult = .noResponse
    var waitingForLocalNetwork = false

    func finish(_ value: TCPProbeResult) {
      lock.lock()
      guard !completed else {
        lock.unlock()
        return
      }
      completed = true
      probeResult = value
      lock.unlock()
      connection.cancel()
      semaphore.signal()
    }

    connection.stateUpdateHandler = { state in
      switch state {
      case .ready:
        finish(.open)
      case .failed(let error):
        finish(self.hostResponded(to: error) ? .responded : .noResponse)
      case .cancelled:
        finish(.noResponse)
      case .waiting:
        if case .localNetworkDenied? = connection.currentPath?.unsatisfiedReason {
          lock.lock()
          waitingForLocalNetwork = true
          lock.unlock()
        }
      default:
        break
      }
    }
    connection.start(queue: DispatchQueue.global(qos: .utility))
    if semaphore.wait(timeout: .now() + .milliseconds(timeoutMs)) == .timedOut {
      lock.lock()
      let shouldWaitForPermission = waitingForLocalNetwork
      lock.unlock()
      if shouldWaitForPermission {
        // iOS may present the Local Network permission prompt after the first
        // connection enters .waiting. Give that prompt time to resolve instead
        // of recording every host as absent during the first scan.
        if semaphore.wait(timeout: .now() + .milliseconds(1500)) == .timedOut {
          finish(.noResponse)
        }
      } else {
        finish(.noResponse)
      }
    }
    lock.lock()
    let value = probeResult
    lock.unlock()
    return value
  }

  private func hostResponded(to error: NWError) -> Bool {
    guard case .posix(let code) = error else { return false }
    return code == .ECONNREFUSED ||
      code == .ECONNRESET ||
      code == .ECONNABORTED
  }

  private func ipv4Value(_ value: String) -> Int64? {
    let parts = value.split(separator: ".").compactMap { Int64($0) }
    guard parts.count == 4, parts.allSatisfy({ $0 >= 0 && $0 <= 255 }) else { return nil }
    return (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3]
  }

  private func ipv4String(_ value: Int64) -> String {
    "\((value >> 24) & 255).\((value >> 16) & 255).\((value >> 8) & 255).\(value & 255)"
  }

  private func subnetPrefix(_ value: String) -> Int? {
    guard let mask = ipv4Value(value) else { return nil }
    var prefix = 0
    var sawZero = false
    for bit in stride(from: 31, through: 0, by: -1) {
      if (mask & (Int64(1) << bit)) != 0 {
        guard !sawZero else { return nil }
        prefix += 1
      } else {
        sawZero = true
      }
    }
    return prefix
  }

  private func prefixMask(_ prefix: Int) -> Int64 {
    prefix == 0 ? 0 : (0xffff_ffff << (32 - prefix)) & 0xffff_ffff
  }
}
