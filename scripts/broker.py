#!/usr/bin/python

# broker - program to install apps on smartphones with bada
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

import serial
import string
import struct
import re
import getopt
import os
import sys

class TimeoutError(Exception):
	def __init__(self):
		pass

class InvalidResponseError(Exception):
	def __init__(self, res):
		self.msg = res

class InvalidCommandError(Exception):
	def __init__(self, cmd):
		self.msg = cmd

def readByChunk(f, chunkSize):
	"""Read file by chunk."""
	while True:
		data = f.read(chunkSize)
		if (data):
			yield data
		else:
			return

toHex = lambda x:"".join([hex(ord(c))[2:].zfill(2) + " " for c in x])

def readStringz(strg, start = 0):
	zpos = strg.index('\0', start)
	return strg[start:zpos]

class SamsungWave:
	"""A class to talk to your phone"""
	def __init__(self, port = '/dev/ttyACM0'):
		"""Yes, this is the constructor. It opens the port, which by default
		is /dev/ttyACM0, as the device appears on my computer under this name."""
		# dsrdtr is ignored on Linux, but here it is included to remind you that the
		# original broker enables it
		self._ser = serial.Serial(port, 115200, timeout = 1, dsrdtr = 1, rtscts = 1)
		self._ser.flushInput()
		self._ser.flushOutput()
		self._recbufs = { 'AT+': [], 'raw': [], 'PHONESTATUS': [], 'PROCESSMGR': [] }
		self._logf = file('broker.log', 'w')
		self._serx = serial.Serial('/dev/ttyACM1', 115200, timeout = 1, dsrdtr = 1, rtscts = 1)
		self._serx.write('AT+WINCOMM\r')
		self._serx.flushInput()
		self._serx.flushOutput()

	def _sread(self, b = 1):
		a = self._ser.read(b)
		n = -1
		if not a is None:
			n = len(a)
		self._logf.write('read:  %5d %5d %s\n' % (b, n, repr(a)))
		return a

	def _sreadline(self):
		a = self._ser.readline()
		n = -1
		if not a is None:
			n = len(a)
		self._logf.write('readl:       %5d %s\n' % (len(a), repr(a)))
		return a

	def _swrite(self, b):
		a = self._ser.write(b)
		self._logf.write('write: %5d       %s\n' % (len(b), repr(b)))
		return a

	def _receive(self, channel, timeout = 1):
		if not channel in self._recbufs:
			return None
		self._ser.timeout = timeout
		while not len(self._recbufs[channel]):
			s = self._sread(1)
			if not s:
				return None
			if s != '\x7f':
				if s != '\n':
					r = self._sreadline()
					if r is None:
						raise InvalidResponseError(r)
					s += r
				self._recbufs['AT+'].append(string.strip(s))
			else:
				rd = self._sread(2)
				rlen = struct.unpack("<H", rd)
				r = self._sread(rlen[0] + 2)
				if r[-1] != '\x7e':
					raise InvalidResponseError(r)
				mo = re.match("\x04([0-9]{5})\|(-?[0-9]+:-?[0-9]+:-?[0-9]+)\|([A-Z]+):(-?[0-9]+)> (.*)", r[0:-1])
				if mo and mo.group(3) in self._recbufs:
					self._recbufs[mo.group(3)].append((
						int(mo.group(1)),
						mo.group(2),
						mo.group(3),
						int(mo.group(4)),
						mo.group(5)))
				else:
					self._recbufs['raw'].append(r[0:-1])
		return self._recbufs[channel].pop(0)

	def _AT(self, command):
		self._swrite(command + "\r\n")
		result = []
		while True:
			r = self._receive('AT+')
			if r is None:
				return None
			if r and r != command:
				result.append(r)
			if r == "OK" or r == "ERROR":
				return result

	def getModel(self):
		"""Query the device for model name. Return string containing
		the received identifier or None, if no valid answer was received."""
		ans = self._AT("AT+CGMM")
		if ans != None and len(ans) == 2 and ans[1] == "OK":
			return ans[0]
		else:
			return None

	def getUserMem(self):
		"""Query the device for user memory size. Return memory size
		in bytes or None, if no valid answer was received."""
		ans = self._AT("AT+USERMEM")
		if ans != None and len(ans) == 2 and ans[1] == "OK":
			mo = re.search("^\+USERMEM:([0-9]+)k$", ans[0])
			if not mo:
				return None
			return int(mo.group(1)) * 1024
		else:
			return None

	def getLcdInfo(self):
		"""Query the device for the LCD dimensions. Return tuple
		(width, height) or None, if no valid answer was received."""
		ans = self._AT('AT+LCDINFO')
		if ans != None:
			if len(ans) == 2 and ans[1] == 'OK':
				mo = re.search('^\+LCDINFO: ([0-9]+), ([0-9]+)$', ans[0])
				if mo:
					return (int(mo.group(1)), int(mo.group(2)))
			elif ans[0] == 'ERROR':
				ans = self._AT('AT+LCDINFO:MAIN')
				if ans != None and len(ans) > 2 and ans[1] == 'OK':
					mo = re.search('^\+LCDINFO: ([0-9]+), ([0-9]+)$', ans[0])
					if mo:
						return (mo.group[1], mo.group[2])
		return None

	def _send(self, cmd, payload):
		"""
		"""
		frame = '\x7f' + struct.pack('<HB', len(payload), cmd) + payload + '\x7e'
		self._swrite(frame)

	def isInstallationPossible(self, appId, nbytes):
		"""
		"""
		self._send(4, "[1600:1601]GetAppInstallCondition %s %d" % ( appId, nbytes ))
		while True:
			r = self._receive('PHONESTATUS', 3)
			if r is None:
				return False
			print r
			mo = re.search('errType=([0-9]+)', r[4])
			if mo:
				return mo.group(1) == '0'

	def appTerminate(self, appId):
		"""
		"""
		self._send(4, "[1600:1601]TerminateProcessEx %s 0" % appId)
		ans = []
		while True:
			r = self._receive('PROCESSMGR')
			if not r:
				return ans
			ans.append(r)

	def appInstall(self, appId):
		self._send(4, '[1600:1601]EnableDiagWrite')
		self._send(4, '[1600:1601]AppPkgInstall /Osp/Applications/' + appId)
		self._send(4, '[0:2]MID_PROCESSMGR,0xFF')
		self._send(4, '[0:2]MID_DIAGMGR,0xFF')
		self._send(4, '[0:2]MID_DIAGMGR,0xFF')
		r = self._receive('PHONESTATUS', 10)
		print r
		mo = re.search('errType=([0-9]+)', r[4])
		if not mo:
			raise InvalidResponseError(r)
		return mo.group(1) == '0'

	def appRun(self, appId, exeFileName):
		self._send(4, '[1400:1400]/Osp/Applications/' + appId + '/Bin/' + exeFileName + ',/Osp/Applications/' + appId + '/Bin')

	_FILE_OPEN = 0x00
	_FILE_CLOSE = 0x01
	_FILE_WRITE = 0x02
	_FILE_READ = 0x03
	_FILE_DELETE = 0x04
	_DIR_CREATE = 0x05
	_DIR_DELETE = 0x06
	_DIR_OPEN = 0x07
	_DIR_READ = 0x08
	_DIR_CLOSE = 0x09

	_CHUNK_SIZE = 0x5dc

	def _fileCommand(self, cmd, payload = ''):
		"""
		"""
		self._send(0x30, struct.pack("<BB", cmd, 0) + payload)
		r = self._receive('raw')
		if ord(r[0]) != 0x30 or ord(r[1]) != (cmd | 0xe0):
			print "Warning: Invalid response for file command %02x: %s" % (cmd, toHex(r))
			return None
		r = struct.unpack("<iHH", r[2:10]) + (r[10:],)
		return r

	def sendFile(self, localFileName, remoteFileName):
		"""
		"""
		f = open(localFileName)
		ans = self._fileCommand(self._FILE_OPEN, "\x09\x00\x00\x00%s\x00" % remoteFileName)
		if ans[0] < 0:
			print "Error: sendFile:", ans
			return
		if ans[1] != 3:
			print "Warning: sendFile:", ans
		for chunk in readByChunk(open(localFileName), self._CHUNK_SIZE):
			ans = self._fileCommand(self._FILE_WRITE, chunk)
			if ans[0] < 0:
				print "Error: sendFile write:", ans
				return
			if ans[1] != 3:
				print "Warning: sendFile write:", ans
		ans = self._fileCommand(self._FILE_CLOSE)
		if ans[0] < 0 or ans[1] != 3:
			print "Warning: sendFile close:", ans
	
	def getFile(self, localFileName, remoteFileName):
		"""
		"""
		f = open(localFileName, 'w')
		ans = self._fileCommand(self._FILE_OPEN, "%s\x00" % remoteFileName)
		if ans[0] != 0:
			print "Error: getFile:", ans
			return
		if ans[1:3] != (3, 6):
			print "Warning: getFile:", ans
		ans = self._fileCommand(self._FILE_READ)
		print ans
		ans = self._fileCommand(self._FILE_CLOSE)

	def deleteFile(self, remoteFileName):
		"""Deletes a file on your phone"""
		ans = self._fileCommand(0x04, "%s\x00" % remoteFileName)
		if ans[0:3] != (0, 3, 6):
			print "Warning: deleteFile:", ans

	def createDirectory(self, remoteDirName):
		"""Supposedly, this should create a directory on your phone."""
		ans = self._fileCommand(0x05, "%s\x00" % remoteDirName)
		if ans[0] < 0:
			print "Error: create directory:", ans
		if ans[1:3] != (3, 6):
			print "Warning: create directory:", ans

	def deleteDirectory(self, remoteDirName, recursive = False):
		"""Based on when and how it is used by the original Broker.exe,
		I would guess this is a command to remove a directory."""
		if recursive:
			for ent in self.readDirectory(remoteDirName):
				if ent[0] == 2 and (not (ent[2] == '.' or ent[2] == '..')):
						self.deleteDirectory(remoteDirName + '/' + ent[2], True)
				elif ent[0] == 1:
					self.deleteFile(remoteDirName + '/' + ent[2])
		ans = self._fileCommand(0x06, "%s\x00" % remoteDirName)
		if ans[0] != 0:
			print "Error delete directory:", ans
		if ans[1:3] != (3, 13):
			print "Warning: delete directory:", ans

	def readDirectory(self, remoteDirName):
		"""Reads a directory and yields a tuple (type, size, name) for each entry.
		type is 1 for a regular file and 2 for a subdirectory."""
		ans = self._fileCommand(self._DIR_OPEN, "%s\x00" % remoteDirName)
		if ans[0] < 0:
			return
		if ans[1:3] != (3, 13):
			print "Warning: open directory:", ans
		while True:
			r = self._fileCommand(self._DIR_READ, "")
			attr, size = struct.unpack("<ii", r[3][0:8])
			name = readStringz(r[3][36:])
			if attr == 0:
				r = self._fileCommand(self._DIR_CLOSE, "")
				if len(r[3]) > 0:
					print "Warning: close directory:", ans
				break
			yield attr, size, name

	def _printport1(self):
		print toHex(self._serx.read(100000))
		print "ok"

	def listFiles(self, remoteDirName):
		for f in self.readDirectory(remoteDirName):
			if f[0] == 2:
				t = '/'
			else:
				t = ''
			print "%8d %s%s" % (f[1], f[2], t)

def install(appid, exename):
	wave = SamsungWave()
	print wave.getModel()
	print wave.getUserMem()
	print wave.getLcdInfo()
	print wave.isInstallationPossible(appid, 440952)
	print wave.appTerminate(appid)

	for fil in [
		"/Osp/Applications/" + appid + "/Data/memdebug_report.txt",
		"/Osp/Applications/" + appid + "/Data/Bin/core",
		"/Osp/Applications/" + appid + "/Data/Bin/Bin/stackFrame.txt",
		"/Osp/Applications/" + appid + "/Data/Bin/Bin/Bin/crashinfo.txt",
		"/Osp/Applications/" + appid + "/Data/memdebug.ini",
		"/Osp/Applications/" + appid + "/Bin/stackFrame.txt",
		"/Osp/Applications/" + appid + "/Bin/stackFrame.txtcore",
		"/Osp/Applications/" + appid + "/Bin/stackFrame.txtcorecrashinfo.txt" ]:
		wave.deleteFile(fil)

	for dirname in [
		'/Osp',
		'/Osp/Applications',
		'/Osp/Applications/' + appid ]:
		print 'create dir %s' % dirname
		wave.createDirectory(dirname)
	
	for dirname, dirnames, filenames in os.walk(appid):
		for subdirname in dirnames:
			localName = os.path.join(dirname, subdirname)
			remoteName = '/Osp/Applications/' + dirname + '/' + subdirname
			print 'create dir %s -> %s' % (localName, remoteName)
			wave.createDirectory(remoteName)

	for dirname, dirnames, filenames in os.walk(appid):
		for filename in filenames:
			localName = os.path.join(dirname, filename)
			remoteName = '/Osp/Applications/' + dirname + '/' + filename
			print 'put file %s -> %s' % (localName, remoteName)
			wave.sendFile(localName, remoteName)

	res = wave.appInstall(appid)
	if res:
		print 'Installed'
	else:
		print 'Failed to install'

	res = wave.appRun(appid, exename)
	while True:
		while True:
			q = wave._serx.readline()
			if q:
				print string.strip(q)
			else:
				break

def main():
	if len(sys.argv) >= 2:
		if sys.argv[1] == 'rmdir':
			wave = SamsungWave()
			for dirname in sys.argv[2:]:
				wave.deleteDirectory(dirname)
			exit(0)
		elif sys.argv[1] == 'ls':
			wave = SamsungWave()
			for dirname in sys.argv[2:]:
				print 'Files in %s:' % dirname
				wave.listFiles(dirname)
			exit(0)
		elif sys.argv[1] == 'rm':
			wave = SamsungWave()
			for filename in sys.argv[2:]:
				wave.deleteFile(filename)
			exit(0)
		elif sys.argv[1] == 'install':
			install(sys.argv[2], sys.argv[3])
			exit(0)
		else:
			print 'Error: unknown command: %s' % sys.argv[1]
			exit(1)
		print 'WTF!'
		exit(1)

if __name__ == "__main__":
	main()
