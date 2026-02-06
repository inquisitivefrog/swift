
(⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % pwd
/Users/tim/Documents/workspace/swift/apps/dino-games/scripts
(⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % python3 -m venv dino-games

(⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % cat ./self_test.py 
#!/usr/bin/env python3

import sys

def in_venv():
    return sys.prefix != sys.base_prefix

if __name__ == '__main__':
    if not in_venv():
        print("source /Users/tim/Documents/workspace/swift/apps/dino-games/scripts/dino-games/bin/activate")
        #print(in_venv())
(⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % ./self_test.py 
source /Users/tim/Documents/workspace/swift/apps/dino-games/scripts/dino-games/bin/activate

(⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % source /Users/tim/Documents/workspace/swift/apps/dino-games/scripts/dino-games/bin/activate
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % ./self_test.py 
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % 

