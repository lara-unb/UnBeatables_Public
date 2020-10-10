from distutils.core import setup
from Cython.Build import cythonize

setup(name="chroma_calculator", ext_modules=cythonize('chroma_calculator.pyx'),)