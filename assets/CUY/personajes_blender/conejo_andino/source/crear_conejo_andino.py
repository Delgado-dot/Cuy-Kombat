import os, sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from common.character_builder import build
build({"name":"conejo_andino","fur":(.46,.18,.055),"cream":(.82,.63,.4),"rabbit":True,"body":(.78,.84,1.08),"head":(.88,.9,.92),"arm_size":.82,"fist_size":.82,"leg_length":1.32,"ear_length":1.05,"left_lift":.18}, __file__)
