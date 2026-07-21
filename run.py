import sys
import os

# Try compiled .so first, fall back to .pyx source
try:
    import skyby
    skyby.main()
except ImportError:
    # .so not compiled yet — run from source
    print("\033[1;33m[!] Compiled module not found. Run: bash build.sh\033[0m")
    print("\033[0;32m[*] Falling back to source mode...\033[0m\n")
    import importlib.util
    spec = importlib.util.spec_from_file_location("skyby", os.path.join(os.path.dirname(__file__), "skyby.pyx"))
    mod  = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    mod.main()
