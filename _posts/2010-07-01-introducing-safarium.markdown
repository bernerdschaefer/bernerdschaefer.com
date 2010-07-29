---
layout: post
title: "Introducing Safarium"
---

I recently switched to Chrome after using Safari for almost 3 years, and have been quite happy so far with the results: the memory footprint seems to be much better than Safari, everything feels incredibly snappy, and I'm now completely addicted to the unified location bar. But there were a few things that drove me absolutely crazy, and apparently I was <a href="http://www.google.com/search?q=chrome+tab+form+elements" target="_blank">not</a> <a href="http://www.google.com/search?q=chrome+command+enter" target="_blank">alone</a>.

## <code>&lt;TAB&gt;</code>
In Safari, when you hit <code>&lt;TAB&gt;</code> it moves your cursor's focus between form elements, making it easy to navigate the page wthout using the mouse. In Chrome (and FireFox), however, <code>&lt;TAB&gt;</code> instead cycles through all clickable elements on the page: links, form elements, etc. When you have been hitting <code>&lt;TAB&gt;</code> for years to, say, skip directly to the search field on Amazon and then discover you need to hit <code>&lt;TAB&gt;</code> 14 times in Chrome to reach the search box, this becomes a killer feature.

## <code>&lt;COMMAND-ENTER&gt;</code>
This is another feature of Safari that I used on a regular basis. When you are within a form and hit <code>&lt;COMMAND-ENTER&gt;</code> in Safari, it will be submitted into a new background tab, allowing you to continue working in your active tab. This behavior exists elsewhere in Chrome: <code>&lt;COMMAND-ENTER&gt;</code> in the location bar will open the page in a background tab, and you can even <code>&lt;COMMAND-CLICK&gt;</code> a form's submit button to open a new tab! But when you <code>&lt;COMMAND-ENTER&gt;</code> from a form element... nothing happens.

## Safarium to the rescue!
After just a few days using Chrome, I became frustrated enough that I broke open the <a href="http://code.google.com/chrome/extensions/index.html">Chrome Extensions documentation</a> and put together my own extension: <a href="http://github.com/bernerdschaefer/safarium">Safarium</a>. Right now it provides the <code>&lt;TAB&gt;</code> and <code>&lt;COMMAND-ENTER&gt;</code> features which I missed so much, and will provide more as seems necessary. It's not up on Chrome's extension site, yet, because it needs a logo and some other things, but you can use these intructions for now to get up and running:

First <a href="http://github.com/bernerdschaefer/safarium/zipball/master">download</a> the extension's ZIP file. If it wasn't automatically extracted, make sure to do so now. Next, in Chrome, pull up your extensions list (Window &gt; Extensions). There should be "Developer Mode" link on the right which when clicked will reveal a few buttons. Click 'Load unpacked extension...', select the unpacked Safarium extension you downloaded, and that's it! Happy <code>&lt;TAB&gt;</code>ing!
