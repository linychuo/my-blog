---
layout: post
title:  "Three things you should never put in your database  "
date:   2014-10-30 09:55:32
categories: db
---

As I've said in a few talks, the best way to improve your systems is by first not doing "dumb things". I don't mean you or your development staff is "dumb", it's easy to overlook the implications of these types of decisions and not realize how bad they are for maintainability let alone scaling. As a consultant I see this stuff all of the time and I have yet to ever see it work out well for anyone.

**Images, files, and binary data**

Your database supports BLOBs so it must be a good idea to shove your files in there right? No it isn't! Hell it isn't even very convenient to use with many DB language bindings.

There are a few of problems with storing files in your database:

read/write to a DB is always slower than a filesystem
your DB backups grow to be huge and more time consuming
access to the files now requires going through your app and DB layers
The last two are the real killers. Storing your thumbnail images in your database? Great now you can't use nginx or another lightweight web server to serve them up.

Do yourself a favor and store a simple relative path to your files on disk in the database or use something like S3 or any CDN instead.

**Ephemeral data**

Usage statistics, metrics, GPS locations, session data anything that is only useful to you for a short period of time or frequently changes. If you find yourself DELETEing an hour, day, or weeks worth of some table with a cron job, you're using the wrong tool for the job.

Use redis, statsd/graphite, Riak anything else that is better suited to that type of work load. The same advice goes for aggregations of ephemeral data that doesn't live for very long.

Sure it's possible to use a backhoe to plant some tomatoes in the garden, but it's far faster to grab the shovel in the garage than schedule time with a backhoe and have it arrive at your place and dig. Use the right tool(s) for the job at hand.

**Logs**

This one seems ok on the surface and the "I might need to use a complex query on them at some point in the future" argument seems to win people over. Storing your logs in a database isn't a HORRIBLE idea, but storing them in the same database as your other production data is.

Maybe you're conservative with your logging and only emit one log line per web request normally. That is still generating a log INSERT for every action on your site that is competing for resources that your users could be using. Turn up your logging to a verbose or debug level and watch your production database catch on fire!

Instead use something like Splunk, Loggly or plain old rotating flat files for your logs. The few times you need to inspect them in odd ways, even to the point of having to write a bit of code to find your answers, is easily outweighed by the constant resources it puts on your system.

But wait, you're a unique snowflake and your problem is SO different that it's ok for you to do one of these three. **No you aren't and no it really isn't**. Trust me.

[http://www.revsys.com/blog/2012/may/01/three-things-you-should-never-put-your-database/](http://www.revsys.com/blog/2012/may/01/three-things-you-should-never-put-your-database/)