#!/usr/bin/env python3

import sys

def in_venv():
    return sys.prefix != sys.base_prefix

if __name__ == '__main__':
    if not in_venv():
        print("source /Users/tim/Documents/workspace/swift/apps/dino-games/scripts/dino-games/bin/activate")
        #print(in_venv())
