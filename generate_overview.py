import runpy
from pathlib import Path

runpy.run_path(str(Path(__file__).parent / 'scripts' / 'generate-overview.py'))

