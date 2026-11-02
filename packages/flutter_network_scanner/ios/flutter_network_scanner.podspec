Pod::Spec.new do |s|
  s.name             = 'flutter_network_scanner'
  s.version          = '1.0.0'
  s.summary          = 'Native local network discovery for Flutter.'
  s.description      = <<-DESC
  Scans local IPv4 networks and probes hosts and ports through a Flutter MethodChannel.
  DESC
  s.homepage         = 'https://github.com/example/flutter_network_scanner'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'flutter_network_scanner' => 'developers@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency       'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'
end
