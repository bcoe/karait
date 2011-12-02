#!/usr/bin/env python
#from distutils.core import setup
from setuptools import setup, find_packages

setup(
    name="karait",
    version="1.0.0",
    description="A ridiculously simple cross-language queuing system, built on top of MongoDB.",
    author="Benjamin Coe",
    author_email="bencoe@gmail.com",
    url="http://github.com/bcoe/karait",
    packages = find_packages(),
    install_requires = [
        'pymongo==2.0.1'
    ],
    tests_require=[
        'nose'
    ]
)