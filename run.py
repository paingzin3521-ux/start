import os
import sys

def main():
    try:
        import requests
    except ImportError:
        os.system("pip install requests")
    
    try:
        import skyby
        skyby.main()
    except ImportError:
        # If not installed as module, try direct execution
        if os.path.exists("skyby.py"):
            os.system(f"{sys.executable} skyby.py")
        else:
            print("Error: skyby.py not found!")

if __name__ == "__main__":
    main()
