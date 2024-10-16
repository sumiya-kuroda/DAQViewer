import os
import re

here = os.path.abspath(os.path.dirname(__file__))

def read(*parts):
    with open(os.path.join(here, *parts), "r") as fp:
        return fp.read()

def find_version(*file_paths):
    version_file = read(*file_paths)
    version_match = re.search(r"^__version__ = ['\"]([^'\"]*)['\"]", version_file, re.M)
    if version_match:
        return version_match.group(1)
    raise RuntimeError("Unable to find version string.")

def normalize_angle_np(angles):
    # Normalize angles using modulo 360
    normalized_angles = angles % 360
    return normalized_angles