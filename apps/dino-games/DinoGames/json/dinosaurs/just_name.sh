#!/usr/bin/env bash
# reduce char_{name}.json to {name}

ls -C1 | awk -F '[.]' '{print $(NF-1)}' | awk -F '_' '{print $NF}' 

