# Paper Enhance
Basic MacOS command line tool to improve photo scans of paper and pencil drawings.
Taking photos of sketches and diagrams is not as simple as if should be. A bit of clean up work is needed to make a good digital rendering. I found that I was doing this a good bit, so I made this simple tool to automate the process. Along the way I discovered that CoreImage has a great function that does most of the leg work better than my hacked together set of dials for contrast and brightness so I use that.

Feel free to use and modify as you see fit (MIT License)

## Usage:

Example:<br>
`PaperEnhance input.jpg output.jpg amount=10 invert=false mask=false`

### Parameters:<br>
1.) **input filename**: file path of the image file you want to use<br>
2.) **output filename**: file path of the place to save the modified image<br>
3.) **amount** (optional, default: 10.0): number to give the intensity of the contrast enhancement<br>
4.) **invert** (optional, default: false): set to true if you want to invert the output (i.e. black lines rendered white like a chalkboard)<br>
5.) **mask** (optional, default: true): set to true if you want to remove the background paper (assumes white paper). Note that this will save the output to a png file even if jpg is specified.<br>
