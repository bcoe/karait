#!/usr/bin/env python
#from distutils.core import setup
from setuptools import setup, find_packages

setup(
    name="karait",
    version="0.0.1",
    description="A ridiculously simple cross-language queuing system, built on top of MongoDB.",
    author="Benjamin Coe",
    author_email="bencoe@gmail.com",
    url="http://github.com/bcoe/karait",
    packages = find_packages(),
    install_requires = [
        'pymongo'
    ],
    tests_require=['nose']
)