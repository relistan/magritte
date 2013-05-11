Dir[File.join(File.dirname(__FILE__), 'magritte', '*')].each do |file|
  require file
end
