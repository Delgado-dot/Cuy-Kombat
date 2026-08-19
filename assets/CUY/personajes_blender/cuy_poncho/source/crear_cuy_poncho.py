import os, sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from common.character_builder import build
build({"name":"cuy_poncho","fur":(.46,.14,.035),"cream":(.82,.61,.39),"body":(1.02,1,1),"head":(1.02,1,1),"arm_size":.95,"fist_size":.95,"poncho":True,"left_lift":.1}, __file__)
