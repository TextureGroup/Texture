Pod::Spec.new do |spec|
  spec.name         = 'Texture'
  spec.version      = '3.2.0'
  spec.license      =  { :type => 'Apache 2',  }
  spec.homepage     = 'http://texturegroup.org'
  spec.authors      = { 'Huy Nguyen' => 'hi@huynguyen.dev', 'Garrett Moon' => 'garrett@excitedpixel.com', 'Scott Goodson' => 'scottgoodson@gmail.com', 'Michael Schneider' => 'mischneider1@gmail.com', 'Adlai Holler' => 'adlai@icloud.com' }
  spec.summary      = 'Smooth asynchronous user interfaces for iOS apps.'
  spec.source       = { :git => 'https://github.com/TextureGroup/Texture.git', :tag => spec.version.to_s }
  spec.module_name  = 'AsyncDisplayKit'
  spec.header_dir   = 'AsyncDisplayKit'

  spec.documentation_url = 'http://texturegroup.org/appledoc/'

  ios_deployment_target = '14.0'
  tvos_deployment_target = '14.0'
  spec.ios.deployment_target = ios_deployment_target
  spec.tvos.deployment_target = tvos_deployment_target

  # Subspecs
  spec.subspec 'Core' do |core|
    core.ios.deployment_target = ios_deployment_target
    core.tvos.deployment_target = tvos_deployment_target
    core.compiler_flags = '-fno-exceptions'
    core.public_header_files = [
      'Source/*.h',
      'Source/Details/**/*.h',
      'Source/Layout/**/*.h',
      'Source/Base/*.h',
      'Source/Debug/**/*.h',
      'Source/Private/ASCollectionView+Undeprecated.h',
      'Source/TextKit/ASTextNodeTypes.h',
      'Source/TextKit/ASTextKitComponents.h',
      'Source/TextExperiment/Component/*.h',
      'Source/TextExperiment/String/ASTextAttribute.h',
    ]

    core.source_files = [
      'Source/**/*.{h,mm}',

      # Most TextKit components are not public because the C++ content
      # in the headers will cause build errors when using
      # `use_frameworks!` on 0.39.0 & Swift 2.1.
      # See https://github.com/facebook/AsyncDisplayKit/issues/1153
      'Source/TextKit/*.h',
    ]
  end

  spec.subspec 'PINRemoteImage' do |pin|
    pin.ios.deployment_target = ios_deployment_target
    pin.tvos.deployment_target = tvos_deployment_target
    pin.dependency 'PINRemoteImage/iOS', '~> 3.0.0'
    pin.dependency 'PINRemoteImage/PINCache'
    pin.dependency 'Texture/Core'
  end

  spec.subspec 'IGListKit' do |igl|
    igl.ios.deployment_target = ios_deployment_target
    igl.tvos.deployment_target = tvos_deployment_target
    igl.dependency 'IGListKit', '~> 4.0'
    igl.dependency 'IGListDiffKit', '~> 4.0'
    igl.dependency 'Texture/Core'
  end

  spec.subspec 'Yoga' do |yoga|
    yoga.ios.deployment_target = ios_deployment_target
    yoga.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) YOGA=1' }
    yoga.dependency 'Yoga', '~> 2.0'
    yoga.dependency 'Texture/Core'
  end

  # If flag is enabled the old TextNode with all dependencies will be compiled out
  spec.subspec 'TextNode2' do |text_node|
    text_node.ios.deployment_target = ios_deployment_target
    text_node.tvos.deployment_target = tvos_deployment_target
    text_node.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) AS_ENABLE_TEXTNODE=0' }
    text_node.dependency 'Texture/Core'
  end

  spec.subspec 'Video' do |video|
    video.ios.deployment_target = ios_deployment_target
    video.tvos.deployment_target = tvos_deployment_target
    video.frameworks = ['AVFoundation', 'CoreMedia']
    video.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) AS_USE_VIDEO=1' }
    video.dependency 'Texture/Core'
  end

  spec.subspec 'MapKit' do |map|
    map.ios.deployment_target = ios_deployment_target
    map.tvos.deployment_target = tvos_deployment_target
    map.frameworks = ['CoreLocation', 'MapKit']
    map.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) AS_USE_MAPKIT=1' }
    map.dependency 'Texture/Core'
  end

  spec.subspec 'Photos' do |photos|
    photos.ios.deployment_target = ios_deployment_target
    photos.tvos.deployment_target = tvos_deployment_target
    photos.frameworks = 'Photos'
    photos.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) AS_USE_PHOTOS=1' }
    photos.dependency 'Texture/Core'
  end

  spec.subspec 'AssetsLibrary' do |assetslib|
    assetslib.ios.deployment_target = ios_deployment_target
    assetslib.tvos.deployment_target = tvos_deployment_target
    assetslib.ios.frameworks = 'AssetsLibrary'
    assetslib.ios.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) AS_USE_ASSETS_LIBRARY=1' }
    assetslib.dependency 'Texture/Core'
  end

  # Include these by default for backwards compatibility.
  # This will change in 3.0.
  spec.default_subspecs = 'Core', 'PINRemoteImage', 'Video', 'MapKit', 'AssetsLibrary', 'Photos'

  spec.social_media_url = 'https://twitter.com/TextureiOS'
  spec.library = 'c++'
  spec.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
    'CLANG_CXX_LIBRARY' => 'libc++'
   }

end
