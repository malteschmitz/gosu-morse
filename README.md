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

## ToDo

* Include external font for menu to ensure cross platform consistency

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
