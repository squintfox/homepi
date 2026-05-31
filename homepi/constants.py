import inspect
import os


class DummyClass:
    pass


# 1 level up from this file ([base_path]/homepi)
BASE_PATH = os.path.dirname(
    os.path.dirname(os.path.abspath(inspect.getsourcefile(DummyClass) or ''))
)
CONFIG_PATH = os.path.join(BASE_PATH)
