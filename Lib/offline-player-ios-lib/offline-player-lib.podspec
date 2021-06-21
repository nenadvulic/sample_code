Pod::Spec.new do |s|
  s.name             = "offline-player-lib"
  s.version          = "0.2.8"
  s.summary          = "Offline player library for FairPlay streaming"
  s.homepage         = "https://gitlab.lab.arte.tv/players/offline-player-ios-lib"
  s.license          = 'Code is MIT, then custom font licenses.'
  s.author           = { "Nenad VULIC" => "nenad@keeponapps.com" }
  s.source           = { :git => "ssh://git@gitlab.lab.arte.tv:2222/players/offline-player-ios-lib.git", :tag => s.version, :branch => 'podspec'}
  
  s.platform     = :ios, '11.0'
  s.requires_arc = true

  s.resource_bundles = {
    'offlinePlayerBundle' => ['player/ARTStreamPlayer/ARTProgressView.xib']
  }
  s.source_files = 'player/ARTStreamPlayer'
  s.swift_version = '5.0'
  s.ios.deployment_target  = '11.0'
  s.frameworks = 'UIKit', 'AVKit'
  s.module_name = 'offline_player'
end
