Warbler::Config.new do |config|
  config.features += ['executable']
  #config.dirs = %w(bin lib config log)
  config.dirs = %w(bin lib)
  config.java_libs += FileList['lib/ojdbc7-12.1.0.2.jar']
end
