
Pod::Spec.new do |s|

  s.name         = "VideoIO"
  s.version      = "2.3.1.lit"
  s.summary      = "Video Input/Output Utilities"

  s.description  = <<-DESC
	Video Input/Output Utilities
                   DESC

  s.homepage     = "https://github.com/digitalmonsters/VideoIO.git"
  s.license      = "MIT"
  s.author             = { "YuAo" => "me@imyuao.com" }
  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.source       = { :git => "git@github.com:digitalmonsters/VideoIO.git", :branch => 'feature/disableTrueDepth', :tag => "#{s.version}" }
  s.source_files = "Sources/VideoIO/*.{swift}"

end
