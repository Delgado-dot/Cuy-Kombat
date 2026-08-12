import os, sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from common.character_builder import build
build({"name":"conejo_volcanico","fur":(.035,.032,.038),"cream":(.075,.065,.07),"rabbit":True,"volcanic":True,"body":(.88,.9,1.12),"head":(.94,.94,.96),"arm_size":1.05,"fist_size":1.08,"leg_length":1.28,"ear_length":1.08,"left_lift":.14}, __file__)
