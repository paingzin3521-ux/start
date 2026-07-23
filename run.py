import sys
import os

try:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import skyby
    skyby.main()
except Exception as e:
    print(f"\033[1;31m[!] Error: {e}\033[0m")
    sys.exit(1)
