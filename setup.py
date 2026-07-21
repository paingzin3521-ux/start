from setuptools import setup
from Cython.Build import cythonize

setup(
    name="skyby",
    ext_modules=cythonize(
        "skyby.pyx",
        compiler_directives={
            "language_level": "3",
            "boundscheck": False,
            "wraparound": False,
        },
    ),
)
