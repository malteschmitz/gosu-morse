# Morse Code Visualizer

Visual [morse code](https://en.wikipedia.org/wiki/Morse_code) decoder (not only) for the [Raspberry Pi](https://en.wikipedia.org/wiki/Raspberry_Pi).

This a rewrite of [morse](https://github.com/malteschmitz/morse) using [Gosu](https://www.libgosu.org/) for Ruby.

## Installation

1. Install [Ruby](https://www.ruby-lang.org)

        brew install ruby
 
1. Install the [SDL 2 library](http://www.libsdl.org/)

        brew install sdl2
  
1. Install [Bundler](http://bundler.io/)

        gem install bundler
  
1. Install required Ruby gems using bundler

        bundle install

## TODO

* Iambic A Mode ignores other paddle press entirely if it starts AND ends while sending --> which is exactly how Iambic A should behave. It's not a bug, it's a feature.
* automatic CpM detection
* swap left and right paddle (and key and tree)
  and display key assignment for left, right and return
* Use Gosu.record to speed up tree drawing
* pause (pause everything and freeze screen)

## Further Ideas

* DXpedition simulation:
  1. Computer calls CQ or QRZ
  2. user answers with her call
  3. if user's input looks like a call:
       computer repeats user's call + 5NN
  4. user gives 5NN TU
  5. if user's input looks like report:
       user's call ends up in a log and
       computer calls CQ or QRZ (goto 1)
     else:
       computer repeats user's call + 5NN or calls CQ (goto 1)
