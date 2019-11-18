#!/bin/bash

rm -R _site
bundle install  --path _vendor/bundle
bundle exec jekyll serve --watch -b ""