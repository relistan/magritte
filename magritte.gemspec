Gem::Specification.new do |s|
  s.name        = 'magritte'
  s.version     = '0.5.7'
  s.date        = '2013-06-06'
  s.summary     = "Simple but powerful wrapper of two-way pipes to/from a sub-process."
  s.description = <<-EOS 
  Magritte is a simple but powerful wrapper to Open3 pipes that makes it easy to handle two-way piping of data into and out of a sub-process. Various input IO wrappers are supported and output can either be to an IO or to a block. A simple line buffer class is also provided, to turn block writes to the output block into line-by-line output to make interacting with the sub-process easier.
  EOS
  s.authors     = ["Karl Matthias"]
  s.email       = 'relistan@gmail.com'
  s.files       =  `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/mydrive/magritte'
  s.require_path = 'lib'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>=2.0.0'
end
