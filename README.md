[![Build Status](https://travis-ci.org/relistan/magritte.png)](https://travis-ci.org/relistan/magritte)
Magritte
========
This is a simple but powerful wrapper to Open3 pipes that makes it
easy to handle two-way piping of data into and out of a sub-process.
Various input IO wrappers are supported and output can either be
to an IO or to a block. A simple line buffer class is also provided,
to turn block writes to the output block into line-by-line output
to make interacting with the sub-process easier.

![Ceci n'est pas une pipe](https://raw.github.com/relistan/magritte/master/assets/ceci-nest-pas-une-pipe.jpg)

What it Does
------------
You have a sub-command that you want to put data into and from which
you want to retrieve the output, much like a Unix command line pipe.
This is a non-trivial operation involving non-blocking reads and writes, the
checking of the state of the input and output IOs, etc.  Magritte
abstracts all of that behind an easy to use, fluent interface.


Usage
-----

####Simplest Use Case
For purposes of showing a simple example, let's say you wanted to
use the command line tool `grep` to filter some input data.  Yes,
you can do this natively in Ruby, but it's a trivial and easy to
understand example. The normal use case would be wrapping an existing
custom command line tool with Ruby. 

But, back to `grep`. To store the output into a `StringIO` you could
do the following:

```ruby
buffer = StringIO.new
Magritte::Pipe.from_input_file('some.txt')
  .out_to(buffer)
  .filtering_with('grep "relistan"')
```

This example will take the contents of `some.txt` and stream it through
`grep "relistan"`, storing the results in `buffer`.

####String as Input

```ruby
data   = "foo\nfoo\nrelistan\n"
buffer = StringIO.new

Magritte::Pipe.from_input_string(data)
  .out_to(buffer)
  .filtering_with('grep "relistan"')
```

This works as above, however the input has been taken from the `data`
string rather than a file.

####IO Stream as Input

```ruby
buffer = StringIO.new
socket = Socket.new(xxx)

Magritte::Pipe.from_input_stream(socket)
  .out_to(buffer)
  .filtering_with('grep "relistan"')
```

####Output to a Block

Rather than outputting the results to a stream, you can provide a block
to `out_to` which will be invoked on each read of output data from the
sub-process.  This allows you to process the data in a stream-like
manner without having to buffer all of the output and then process it

NOTE: Like a call to `IO.write`, the block _must_ return the number of 
bytes processed.  This is fed back to the buffering process to make
sure that the next iteration of data will include any missed bytes 
when sent to your output block.

```ruby
Magritte::Pipe.from_input_file('some.txt')
  .out_to { |data| $stdout.write data; data.size }
  .filtering_with('grep "relistan"')
```

Each block of data that was read from the `stdout` of the sub-process
`grep` is passed to the `out_to` block. Note that this is a block of
data of uncertain size, and will not end on nice line boundaries.

####Line Buffering

When passing data into your block, it's often much easier to work on
it if you can access it line-by-line rather than as a stream of data.
Magritte supports this with a provided `LineBuffer` class that is
wrapped into the API. You simply call `line_by_line` and your `out_to`
block will be invoked on each line, one at a time.  Note that when
using the `LineBuffer` you do *not* need to specify the number of bytes
written by your `out_to` block as the `LineBuffer` handles this for you.

```ruby
Magritte::Pipe.from_input_file('some.txt')
  .line_by_line
  .out_to { |data| puts data }
  .filtering_with('grep "relistan"')
```

Note that line buffering does not apply to stream outputs, only to 
output blocks as there is generally no reason to do this with a stream.

####Line Buffer with Arbitrary Record Separators

The default line ending character for the `LineBuffer` is the Unix 
linefeed '\n' character.  You can, however, use any record separator
you like.  It is done like this (e.g. for Windows line endings):

```ruby
Magritte::Pipe.from_input_file('some.txt')
  .separated_by("\r\n")
  .line_by_line
  .out_to { |data| puts data }
  .filtering_with('grep "relistan"')
```

Exit Status
-----------
Magritte will raise an `Errno::EPIPE` in the event of a non-zero
status code in the sub-process.

Limitations
-----------
To simplify implementation, Magritte uses `Open3.popen2e` which combines
`stderr` and `stdout` on the output stream.  This means that in the event
of an error in the sub-process, any output will be contained in the same
output stream as the rest of the data.  I've found that ordinarily this
is what you want, but it might not work for all situations.  If there is
enough interest, I may implement a more complicated alternative later.

In line-by-line mode with an output block provded to `.out_to`, the output
*must* provide a terminating record separator or the last line will not
be passed to the block.

Credits
-------
This software was written by [Karl Matthias](https://github.com/relistan).
[The name](http://en.wikipedia.org/wiki/The_Treachery_of_Images) 
was suggested by [Gavin Heavyside](https://github.com/gavinheavyside).
Magritte was developed with the support of 
[MyDrive Solutions Limited](http://mydrivesolutions.com).

License
-------
This plugin is released under the BSD two clause license which is
available in both the Ruby Gem and the source repository.
