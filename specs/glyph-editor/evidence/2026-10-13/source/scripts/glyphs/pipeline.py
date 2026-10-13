"""Reproducible Matrix glyph pipeline.

sheet raster -> per-glyph slice -> potrace (or hand-edited override SVG) -> cleaned outline
-> TTF -> checks (topology, IoU, winding, film orientation) -> proof sheet + manifest.

Run from the Dreams root with the project venv:
  .venv/bin/python scripts/glyphs/pipeline.py build     # build research/glyphs/build/
  .venv/bin/python scripts/glyphs/pipeline.py verify    # rebuild in a temp dir, compare hashes
  .venv/bin/python scripts/glyphs/pipeline.py adopt G04 # copy an outline to overrides/ for hand editing
  .venv/bin/python scripts/glyphs/pipeline.py lock      # accept intentional changes of frozen inputs
"""
import argparse
import hashlib
import json
import platform
import shutil
import subprocess
import sys
import tempfile
import tomllib
from importlib.metadata import version
from pathlib import Path

import numpy as np
from PIL import Image
from fontTools.misc.transform import Transform

import font as fontlib
import proof
import raster
import vector

ROOT = Path(__file__).resolve().parents[2]
RESEARCH = ROOT / 'research/glyphs'
CONFIG = RESEARCH / 'pipeline.toml'
LOCK = RESEARCH / 'inputs.lock.json'
DEFAULT_OUT = RESEARCH / 'build'
FILM = RESEARCH / 'sources/film-masks'
