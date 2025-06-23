import runpy
from pathlib import Path

# Execute the actual generator script as if it were run directly
runpy.run_path(str(Path(__file__).parent / 'scripts' / 'generate-overview.py'), run_name='__main__')
