use_frameworks!

workspace 'VimeoNetworking'
xcodeproj 'VimeoNetworking/VimeoNetworking.xcodeproj'
xcodeproj 'VimeoNetworkingExample-iOS/VimeoNetworkingExample-iOS.xcodeproj'

def shared_pods
    pod 'AFNetworking', '3.1.0'
end

target 'VimeoNetworking' do
	xcodeproj 'VimeoNetworking/VimeoNetworking.xcodeproj'
	shared_pods
end

target 'VimeoNetworkingExample-iOS' do
	xcodeproj 'VimeoNetworkingExample-iOS/VimeoNetworkingExample-iOS.xcodeproj'
	shared_pods
end

target 'VimeoNetworkingExample-iOSTests' do
	xcodeproj 'VimeoNetworkingExample-iOS/VimeoNetworkingExample-iOS.xcodeproj'
	shared_pods
end

target 'VimeoNetworkingExample-iOSUITests' do
	xcodeproj 'VimeoNetworkingExample-iOS/VimeoNetworkingExample-iOS.xcodeproj'
	shared_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '2.3'
    end
  end
end
