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

* decoding
* typing of letters through the keyboard
* automatic CpM detection
* swap left and right paddle (and key and tree)
* Use Gosu.record to speed up tree drawing

## Further Ideas

* Contest simulation: Computer calls CQ, user can answer, computer repeats call + 5NN, user gives 5NN, call ends up in a log
