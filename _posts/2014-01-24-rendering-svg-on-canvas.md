---
title: "Rendering SVG on Canvas"
category: javascript
description: "Simple example for rendering SVG on a Canvas element with
JavaScript, including simple support for retina screens."
redirect_from: /2014/01/24/rendering-svg-on-canvas/
---

I've been looking into SVG rendering on canvas and a lot of people recommend
using [canvg][1]. I'm not trying to dynamically generate the SVG, manipulate it
in any special way, or use any advanced SVG features. So, as far as I can tell
for basic rendering in modern browsers you can just render the SVG as an image.

```javascript
var image   = new Image();
var canvas  = document.querySelector("canvas");
var context = canvas.getContext("2d");

image.onload = function() {
  context.drawImage(image, 0, 0);
};
image.src = "/path/to/image.svg";
```
{: caption="Drawing an SVG image to a &#60;canvas&#62; element."}

You should probably prefetch or inline the SVG assets, but that's beyond the
scope here.

## Retina Screens

If you're on a retina screen the first thing you'll notice is that it's blurry.
Luckily it's an easy fix with three simple steps.

```javascript
var image   = new Image();
var ratio   = window.devicePixelRatio || 1;
var canvas  = document.querySelector("canvas");
var context = canvas.getContext("2d");

// 1. Ensure the element size stays the same.
canvas.style.width  = canvas.width + "px";
canvas.style.height = canvas.height + "px";

// 2. Increase the canvas dimensions by the pixel ratio.
canvas.width  *= ratio;
canvas.height *= ratio;

image.onload = function() {
  // 3. Scale the context by the pixel ratio.
  context.scale(ratio, ratio);
  context.drawImage(image, 0, 0);
};
image.src = "/path/to/image.svg";
```
{: caption="Scaling the &#60;canvas&#62; element to handle retina screens."}

An added benefit with the scaling is that you can apply a multiplier for
user-specified scaling, via zoom or mousewheel events. And since it's using
SVG it stays incredibly clear.

## Resources

* [Using SVG][2], for an overview of more general SVG usage.
* [SVG optimizer][3], to help reduce the file size even more.
* [SVG browser support][4], not specific to canvas usage.

[1]: https://github.com/canvg/canvg
[2]: https://css-tricks.com/using-svg/
[3]: https://github.com/svg/svgo
[4]: https://caniuse.com/?search=svg
