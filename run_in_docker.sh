#!/bin/bash

docker run --rm --name kurisu-hexo \
 -v $PWD:/app \
 -p 4000:4000 \
 kurisu9/hexo-util:alpine3.13