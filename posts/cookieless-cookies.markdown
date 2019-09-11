---
title: "Cookieless cookies"
date_time: 2019-09-11 20:43:30
tags: cookies
---

# Cookieless cookies
There is another obscure way of tracking users without using cookies or even Javascript. It has [already been used](http://en.wikipedia.org/wiki/HTTP_ETag#Tracking_using_ETags) by numerous websites but few people know of it. This page explains how it works and how to protect yourself.


This tracking method works without needing to use:
- Cookies
- Javascript
- LocalStorage/SessionStorage/GlobalStorage
- Flash, Java or other plugins
- Your IP address or user agent string
- Any methods employed by [Panopticlick](https://panopticlick.eff.org/)
Instead it uses another type of storage that is persistent between browser restarts: **caching**.

Even when you disabled cookies entirely, have Javascript turned off and use a VPN service, this technique will still be able to track you.
<hr/>

## [Demonstration](http://lucb1e.com/rp/cookielesscookies/)

## So how does this work?
This is a general overview:

![etags](/imgs/etags.jpg)

The ETag shown in the image is a sort of checksum. When the image changes, the checksum changes. So when the browser has the image and knows the checksum, it can send it to the webserver for verification. The webserver then checks whether the image has changed. If it hasn't, the image does not need to be retransmitted and lots of data is saved.

Attentive readers might have noticed already how you can use this to track people: the browser sends the information back to the server that it previously received (the ETag). That sounds an awful lot like cookies, doesn't it? The server can simply give each browser an unique ETag, and when they connect again it can look it up in its database.

Technical stuff (and bugs) specifically about this demo
To demonstrate how this works without having to use Javascript, I had to find a piece of information that's relatively unique to you besides this ETag. The image is loaded after the page is loaded, but only the image contains the ETag. How can I display up to date info on the page? Turns out I can't really do that without dynamically updating the page, which requires javascript, which I wanted to avoid to show that it can be done without.

This chicken and egg problem introduces a few bugs:
- All information you see was from your previous pageload. Press F5 to see updated data.
- When you visit a page where you don't have an ETag (like incognito mode), your session will be emptied. Again, this is only visible when you reload the page.

I did not see a simple solution to these issues. Sure some things can be done, but nothing that other websites would use, and I wanted to keep the code as simple and as close to reality as possible.

Note that these bugs normally don't exist when you really want to track someone because then you don't intend to show users that they are being tracked.

### Source code
What's a project without source code? Oh right, Microsoft Windows.

[https://github.com/lucb1e/cookielesscookies](https://github.com/lucb1e/cookielesscookies)

## What can we do to stop it?
One thing I would strongly recommend you to do anytime you visit a page where you want a little more security, is opening a private navigation window and using https exclusively. Doing this single-handedly eliminates attacks like BREACH (the latest https hack), disables any and all tracking cookies that you might have, and also eliminates cache tracking issues like I'm demonstrating on this page. I use this private navigation mode when I do online banking. In Firefox (and I think MSIE too) it's Ctrl+Shift+P, in Chrome it's Ctrl+Shift+N.

Besides that, it depends on your level of paranoia.

I currently have no straightforward answer since cache tracking is virtually undetectable, but also because caching itself is useful and saves people (including you) time and money. Website admins will consume less bandwidth (and if you think about it, in the end users are the ones that will have to pay the bill), your pages will load faster, and especially on mobile devices it makes a big difference if you don't have an unlimited 4G plan. It's even worse when you have a high-latency or low-bandwidth connection because you live in a rural area.

If you're very paranoid, it's best to just disable caching altogether. This will stop any such tracking from happening, but I personally don't believe it's worth the downsides.

The Firefox add-on Self-Destructing Cookies has the ability to empty your cache when you're not using your browser for a while. This might be an okay alternative to disabling caching; you can only be tracked during your visit, and they can already do that anyway by following which pages were visited by which IP address, so that's no big deal. Any later visits will appear as from a different user, assuming all other tracking methods have already been prevented.

I'm not aware of any add-on that periodically removes your cache (e.g. once per 72 hours), but there might be. This would be another good alternative for 99% of the users because it has a relatively low performance impact while still limiting the tracking capabilities.

**Update**: I've heard the Firefox add-on SecretAgent also does ETag overwriting to prevent this kind of tracking method. You can whitelist websites to re-enable caching there while blocking tracking by other domains. It has been confirmed that this add-on stops the tracking. SecretAgent's website.

[Origin Links of this article](http://lucb1e.com/rp/cookielesscookies/)
