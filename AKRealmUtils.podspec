Pod::Spec.new do |s|
  s.name             = 'AKRealmUtils'
  s.version          = '1.0.3'
  s.summary          = 'Realm tools'

  s.description      = <<-DESC
This library simplifies workflow with Realm and provides some helper methods for mapping via Marshal
                       DESC

  s.homepage         = 'https://github.com/Artem-Kalmykov/AKRealmUtils'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Artem-Kalmykov' => 'ar.kalmykov@yahoo.com' }
  s.source           = { :git => 'https://github.com/Artem-Kalmykov/AKRealmUtils.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.swift_version = '5.0'

  s.source_files = 'AKRealmUtils/Classes/**/*'

  s.dependency 'Realm'
  s.dependency 'RealmSwift'
end
