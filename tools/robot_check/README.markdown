# Robot Tidy Tool

Tool for checking and correcting Robot Framework code formatting.

## Installation

The `robot.tidy` Python module ships with the Robot Framework Python package.

We recommend using a [Virtual Environment][1] to manage Python modules.

    $ mkvirtualenv tidy
    $ pip install -r requirements.txt

## Usage

The `tidy.sh` script is a wrapper around `robot.tidy` that checks all files in
the Integration/Test repository.

Use the `check` argument to report problems without correcting them.

    $ ./tidy.sh check

Use the `tidy` argument to automatically clean up all problems.

    $ ./tidy.sh tidy

[1]: https://virtualenvwrapper.readthedocs.io/en/latest/ "Virtualenvwrapper docs"
