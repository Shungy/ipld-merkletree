#!/usr/bin/env python3
import base64
import sys

hex_string = sys.argv[1]
byte_array = bytearray.fromhex(hex_string)
base64_val = base64.b64encode(byte_array)
print(base64_val)
