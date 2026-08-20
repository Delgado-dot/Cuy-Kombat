import os, sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from common.character_builder import build
build({"name":"cuy_blanco","fur":(.88,.86,.82),"cream":(.94,.9,.84),"body":(.78,.86,.9),"head":(.9,.9,.9),"arm_size":.78,"fist_size":.8,"eye_scale":1.04,"left_lift":.22}, __file__)
