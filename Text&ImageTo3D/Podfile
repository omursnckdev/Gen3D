# Podfile for MeshyApp
platform :ios, '16.0'

target 'MeshyApp' do
  use_frameworks!

  # Firebase
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'Firebase/Analytics'
  pod 'Firebase/Messaging'

  # Networking
  pod 'Alamofire', '~> 5.8'

  # Image Processing
  pod 'Kingfisher', '~> 7.10'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
