import sys
import os

# Try compiled .so first
try:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import importlib.util
    so_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "skyby.so")
    pyx_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "skyby.pyx")

    if os.path.exists(so_path):
        spec = importlib.util.spec_from_file_location("skyby", so_path)
        mod  = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        mod.main()
    elif os.path.exists(pyx_path):
        spec = importlib.util.spec_from_file_location("skyby", pyx_path)
        mod  = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        mod.main()
    else:
        print("\033[1;31m[!] skyby.so not found. Run: bash build.sh\033[0m")
        sys.exit(1)
except Exception as e:
    print(f"\033[1;31m[!] Error: {e}\033[0m")
    sys.exit(1)
