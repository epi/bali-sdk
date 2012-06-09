#!/usr/bin/python

# genhtb - program to generate hashtable files for bada applications
# Copyright (C) 2012 Adrian Matoga
#
# bali-sdk is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# bali-sdk is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with bali-sdk.  If not, see <http://www.gnu.org/licenses/>.

import sys
import hashlib
import struct
import xml.dom.minidom

class BadaManifest:
	"""Class for parsing bada manifest files"""
	def __init__(self, manifestFile):
		self.dom = xml.dom.minidom.parse(manifestFile)
		self.appId = self.dom.getElementsByTagName("Id")[0].childNodes[0].data
		self.secret = self.dom.getElementsByTagName("Secret")[0].childNodes[0].data
		self.version = self.dom.getElementsByTagName("AppVersion")[0].childNodes[0].data
	
def readByChunk(fileObject, chunkSize):
	while True:
		data = fileObject.read(chunkSize)
		if not data:
			break
		yield data

def writeString(fileObject, s):
	fileObject.write(struct.pack("<I", len(s)))
	fileObject.write(s)

if len(sys.argv) != 2 and len(sys.argv) != 4:
	print "Usage:\n", sys.argv[0], "manifest_file [exe_file htb_file]"
	exit(1)

manifest = BadaManifest(sys.argv[1])
version = "1000" # TODO: encode app version based on manifest!
headerLength = len("Hash") + 4 + 4 + 4 + len(manifest.appId) + 4 + len(version) + 4 + len(manifest.secret)

print "id:     ", manifest.appId
print "secret: ", manifest.secret
print "version:", manifest.version 

if len(sys.argv) == 4:
	inf = open(sys.argv[2])
	outf = open(sys.argv[3], 'w')

	outf.write("Hash")
	outf.write(struct.pack("<II", 1, headerLength))
	writeString(outf, manifest.appId)
	writeString(outf, version)
	writeString(outf, manifest.secret)

	for piece in readByChunk(inf, 4096):
		s = hashlib.sha1()
		s.update(piece)
		outf.write(s.digest())
