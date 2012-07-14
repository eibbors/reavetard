# Reavetard

  [![Reavetard](http://eibbors.com/p/reavetard/img/scan.png)](http://github.com/eibbors/reavetard)

  Enhancements for Reaver-WPS PIN cracker, including support for multiple target AP rotation, extra annotations / colored output for both reaver and wash, plus some much needed database and session file utilities.

## Scanning

  [![Wash Survey++](http://eibbors.com/p/reavetard/img/scanning.jpg)](http://github.com/eibbors/reavetard)

  Scans contain extra information, such as history and session data, when available. You also have the option to pull *everything* out of the database and stored sessions, allowing for lightning fast target generation.

## Target Review

  [![Target Review](http://eibbors.com/p/reavetard/img/target_review.jpg)](http://github.com/eibbors/reavetard)

  Once you've generated targets via a scan or database dump, the information is sorted, categorized by level of completion, and indexed for selection. Once selected, you're prompted with a list of actions Reavetard can take. The most common being...

## Attack Mode

  [![Attacking](http://eibbors.com/p/reavetard/img/attacking.jpg)](http://github.com/eibbors/reavetard)
  
  The beauty of Reavetard's attack mode is that it automatically rotates to the next target when locked, failing repetetively, having association issues, and so on. The 'very verbose' argument makes debugging reaver issues much simpler, but generates many lines of output for each PIN checked. Reavetard takes the same output and formatted it into groups of like information, allowing more information to be displayed without sacrificing readability. (note: screen shot is outdated)

## About her

  Reavetard is a pet project that evolved out of some small shell scripts I made to correct some annoying parts of the Reaver WPS workflow. 

  The name is a subtle, yet striking, eloquently sophisticated play on the words Reaver and Retard that simply rolls off the tongue as if it were butter on a steaming pile of fresh human feces. It's the kind of project title you can feel comfortable bringing home to meet Meema and Peepop.

## Installation

  $ npm install reavetard

  Currently only designed to run/tested on Backtrack 5 R2, but it should work on any Linux system supported by reaver. I'm happy to help out, if you're having trouble installing her.

## Usage 

  coffee src/reavetard [options] command

  Specifics on their way...

## License

  See LICENSE file

<3 Always

Eibbor Srednuas
http://eibbors.com/

