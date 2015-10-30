import sys
import faketime
import fakefail

from robot import run_cli

# Run the original Robot.
fakefail.initialize()
faketime.initialize()
run_cli(sys.argv[1:])
