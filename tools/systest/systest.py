import sys
import fakefail

from robot import run_cli

# Run the original Robot.
fakefail.initialize()
run_cli(sys.argv[1:])
