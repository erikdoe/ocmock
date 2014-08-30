---
layout: post
title: Switch to NSProxy
tags:
- Design
status: publish
type: post
published: true
---
Changed a small but important detail; the MockObject and MockRecorder classes now inherit from NSProxy which carries much less baggage in terms of methods that cannot be mocked because they are defined by the base class.
