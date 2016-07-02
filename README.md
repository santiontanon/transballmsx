# Transball (MSX) by Santiago Ontañón Villar

## Introduction

In the distant future the sun around your planet has died off... The only energy source are the "energy spheres". Each of these spheres contains enough energy for a planet to survive for a whole decade, since they are charged with the energy of other stars. 

An opportunist civilization has stolen all the charged spheres from your home planet, preparing for a future invasion. As a last chance, the last remaining sources of energy have been transfered to a scout ship and sent to recover the spheres... this is your last chance of survival!


## Instructions

Screenshots:

![title screen](https://github.com/santiontanon/transballmsx/blob/master/screenshots/v1.0/sshot1.png?raw=true)
![in game 1](https://github.com/santiontanon/transballmsx/blob/master/screenshots/v1.0/sshot2.png?raw=true)

![in game 2](https://github.com/santiontanon/transballmsx/blob/master/screenshots/v1.0/sshot3.png?raw=true)
![in game 3](https://github.com/santiontanon/transballmsx/blob/master/screenshots/v1.0/sshot4.png?raw=true)


Demo video ov version 1.0.1 can be found at: https://www.youtube.com/watch?v=uLxYm5E4HOA

Demo of the updates in version 1.1 can be found at: https://www.youtube.com/watch?v=tCYXHnjSeAo

Download latest compiled ROM from: https://github.com/santiontanon/transballmsx/releases/tag/1.1

You will need an MSX emulator to play the game, for example OpenMSX: http://openmsx.org

In each level of Transball, the goal is to find the energy sphere, capture it and carry it to the upper part of the level. The main obstacle is the gravity, that pulls you towards the ground. But many other obstacles such as canons, tanks, doors, etc. will make your journey harder than it seems.

In order to capture the energy sphere, just touch it with your ship.

Some times, parts of a level are blocked out by doors. Some doors get open or closed when you grab the energy sphere, and some others require you to press buttons. To press a button, just fire upon it with your ship.

Be careful with fuel usage. Using the thrusters in the ship uses fuel, and you will have a limited amount in each level. Some levels feature a fuel recharge station. Just fly into the fuel recharge station to replenish your fuel reserve.

There is a high score system in the game, based around how fast can you complete every level. Beat each level as fast as possible and show off in youtube!

Finally, this game uses a password system, so be sure to write down those passwords if you want to continue where you left off! The password is displayed before each level starts. You can select the "password" option in the main menu to enter the level code and continue where you left off. 


## Controls

Keyboard:
* Left/right arrow keys - rotate the ship
* Up arrow key/M        - thrust
* Space                 - fire

Joystick:
* LEft/Right   - rotate the ship
* Up/Trigger B - thrust
* Trigger A    - fire

In the title screen:
* Up/down arrow keys to change the selected menu item
* Space/Trigger A to select a menu item


## Compatibility

The game was designed to be played on MSX1 computers with at least 64KB of RAM. The game speed was tuned to be played on European 50Hz machines. Although the game might run in Japanese 60Hz machines, you might experience glitches (since most likely the CPU is not fast enough to run the game at 60 frames per second). I used the Philips VG8020 as the reference machine (since that's the MSX I owned as a kid).


## Notes from the author and acknowledgments:

I've always been a "thrust-like" games fan. For some reason I never discovered this genre during the 8-bit era, but when I first played "Zarathrusta" (https://en.wikipedia.org/wiki/Zarathrusta), on the Amiga, I thought I had found one of my favorite genres. I became so obsessed with Zarathrusta that I created my own take on the genre for DOS, which I called "Transball". I made numerous versions of Transball (Transball 2, Super Transball 2, Transball GL) over the years. So, one day I decided to just "remake" Transball for the MSX, and this is the result! If you want to check the PC versions, they can be found here:
* http://www.braingames.getput.com/stransball2
* http://www.braingames.getput.com/transballgl (unfinished, I need to finish it one day)

### Concerning the source code:
I used this chance to learn how to program in assembler for the Z80 (this is my first complete game in assembler ever, and also the first time I programmed in assembler for the Z80, so go easy on the code if you take a look at it!). While learning how to code for it, I borrowed many ideas and code snippets for several routines (all of which are acknowledged in the code), but a list of the resources I used (in case they can be useful to other people) are:
* To measure code execution time: http://msx.jannone.org/bit/
* Math routines: http://z80-heaven.wikidot.com/math
* PSG example: https://www.msx.org/forum/development/msx-development/music-how-code-music-asm-or-without-bios-routines
* PSG (sound) registers: http://www.angelfire.com/art2/unicorndreams/msx/RR-PSG.html
* Z80 tutotial: http://sgate.emt.bme.hu/patai/publications/z80guide/part1.html
* Z80 user manual (I used this HEAVILY!): http://www.zilog.com/appnotes_download.php?FromPage=DirectLink&dn=UM0080&ft=User%20Manual&f=YUhSMGNEb3ZMM2QzZHk1NmFXeHZaeTVqYjIwdlpHOWpjeTk2T0RBdlZVMHdNRGd3TG5Ca1pnPT0=
* MSX system variables: http://map.grauw.nl/resources/msxsystemvars.php
* MSX bios calls: 
    * http://map.grauw.nl/resources/msxbios.php
    * https://sourceforge.net/p/cbios/cbios/ci/master/tree/
* VDP reference: http://bifi.msxnet.org/msxnet/tech/tms9918a.txt
* VDP tutorial: http://map.grauw.nl/articles/vdp_tut.php
* VDP manual: http://map.grauw.nl/resources/video/texasinstruments_tms9918.pdf
* Finally, I heavily used the development forums at msx.org, frequented by awesome and very responsive people without whom I would have never been able to figure out many things (e.g., https://www.msx.org/forum/msx-talk/development/memory-pages-again)
The game was compiled with Grauw's Glass compiler (cannot thank him enough for creating it):
* https://bitbucket.org/grauw/glass

### Concerning the graphics:
* I drew all the graphics myself using GIMP and a couple of small tools I coded in Java. I started by converting all the graphics I drew for "Super Transball 2" to the MSX color palette, and then I edited them. They were converted automatically to hex with another little script I wrote. The font was adapted from the one in Thexder (one of my favorite MSX games), although I had to draw some of the characters from scratch, since I could not find any text in Thexder that used some of the letters (e.q., the "Q"). I also redid the numbers, since I didn't like the Thexder ones.

### Concerning the music:
* I know, I know, the music leaves much to be desired. I wrote a quick and dirty song by just adding some arpeggios to a basic bass line just to test my music playing routines, and I eventually left the song there. But I should write a better song for future version. I'll come!
* Also, the song only plays in the menu, since I used 3 channels for the song, and during the game I need one for the SFX. So, instead of worrying about composing a song where one of the channels can be easily silenced for the SFX, I just decided to play the music only in the menu. That's also something to be improved upon.


