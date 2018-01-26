# Uncomment the next line to define a global platform for your project

platform :ios, '9.0'

target 'ATParse' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # No mostrar warnings para librerías ajenas
  inhibit_all_warnings!

  # Pods for ATParse

  pod 'Parse'
  
  pod 'ParseFacebookUtilsV4'
  
  # Disable Code Coverage for Pods projects except MyPod
  post_install do |installer_representation|
	  installer_representation.pods_project.targets.each do |target|
		  if target.name == 'ATParse'
			  target.build_configurations.each do |config|
				  config.build_settings['CLANG_ENABLE_CODE_COVERAGE'] = 'YES'
			  end
			  else
			  target.build_configurations.each do |config|
				  config.build_settings['CLANG_ENABLE_CODE_COVERAGE'] = 'NO'
			  end
		  end
	  end
  end

  target 'ATParseTests' do
    inherit! :search_paths
    # Pods for testing
  end

end
