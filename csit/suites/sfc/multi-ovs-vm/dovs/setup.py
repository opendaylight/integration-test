
from __future__ import with_statement
from setuptools import setup

classifiers = [
    "Programming Language :: Python :: 2",
    "Intended Audience :: Developers",
    "Topic :: Utilities",
]

with open("README", "r") as fp:
    long_description = fp.read()

setup(name="dovs",
      version='0.2.0',
      author="Jaime Caamaño",
      author_email="jaime.caamano.ruiz@ericsson.com",
      py_modules=["dovs"],
      description="ovs-docker companion utility",
      long_description=long_description,
      classifiers=classifiers,
      install_requires=[
          "plumbum",
          "tortilla",
          "ipaddress"
      ],
      entry_points={
          'console_scripts' : [
              'dovs = dovs:main'
          ]
      }
      )
