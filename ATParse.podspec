#
#  Be sure to run `pod spec lint ATParse.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "ATParse"
  s.version      = "1.0.8"
  s.summary      = "Library for easy Parse Server interaction."
  s.description  = "This library makes it easy to fetch data from a Parse server"
  s.homepage     = "http://EXAMPLE/ATParse"
  s.license      = "MIT"
  s.author             = { "Nico Landa" => "machukkas@gmail.com" }


  s.platform     = :ios
  s.ios.deployment_target = '9.0'

  s.source       = { :git => 'https://github.com/machukas/ATParse.git' }

  s.source_files  = "ATParse/**/*.{h,m,swift}"

  s.dependency "Parse"
  s.dependency "ATLogger"
  s.dependency "ParseTwitterUtils"
  s.dependency "ParseFacebookUtilsV4"

end
