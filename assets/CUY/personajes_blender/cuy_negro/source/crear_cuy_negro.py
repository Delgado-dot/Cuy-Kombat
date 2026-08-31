import os, sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from common.character_builder import build
build({"name":"cuy_negro","fur":(.018,.012,.014),"cream":(.04,.032,.032),"body":(1.16,1.05,1.08),"head":(1.08,1.03,1.05),"arm_size":1.28,"fist_size":1.3,"eye_scale":.92,"left_lift":.12}, __file__)
