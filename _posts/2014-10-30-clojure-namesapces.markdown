---
layout: post
title:  "clojure namespaces"
date:   2014-10-30 09:35:32
categories: clojure
---

	(resolve sym)

*resolve* returns namesapce of a variable or class.

If you want switch another namespace, You should using *in-ns*:

	(in-ns name)

On the clojure, *import* tag only import java class

	(import '(java.io InputStream File))
	=> nil
	use=> File/separator
	=> "/"

But you want import some vaiables which was defined in the clojure code, using *require*

	(require 'clojure.contrib.math)
	(clojure.contrib.math/round 1.7)
	=> 2
	(round 1.7)
	=> java.lang.Exception:Unable to resolve symbol: round in this context

If you want import a method into current namespace, you should using *use* tag

	(use 'clojure.contrib.math)
	=> nil
	(use '[clojure.contrib.math :only (round)])
	(round 1.2)
	=> 2

Behind *:only* tag, what you want import

	(ns name & references)

*ns* tag was created new namespace, It contains *:import*, *:require*, *:use*

	(ns examples.exploring
    	(:use examples.utils clojure.contrib.str-utils)
    	(:import (java.io File)))