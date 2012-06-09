#!/usr/bin/python

# signing - program to generate signature files for bada apps
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

# Warning: Requires pyOpenSSL 0.13

import sys
import base64
import re
import getopt
from os import path
from OpenSSL import crypto

class Signer:
	def __init__(self, keyfile, passphrase):
		self._key = crypto.load_privatekey(crypto.FILETYPE_PEM, file(keyfile).read(), passphrase)

	def signFiles(self, *filelist):
		data = ''.join(file(f).read() for f in filelist)
		signature = crypto.sign(self._key, data, 'sha1')
		return base64.b64encode(signature)

def stripCertificate(certfile):
	cert = crypto.load_certificate(crypto.FILETYPE_PEM, file(certfile).read())
	mo = re.match(
		# only rough check for sth that looks more or less like base64 encoded string
		'-----BEGIN CERTIFICATE-----\r?\n((([A-Za-z0-9+/=]{4})+\r?\n)*)-----END CERTIFICATE-----\r?\n\Z',
		crypto.dump_certificate(crypto.FILETYPE_PEM, cert))
	if mo:
		return base64.b64encode(base64.b64decode(mo.group(1)))
	else:
		raise TypeError, 'Invalid certificate dump syntax'

def usage():
	print '''{0} generates signature files for bada applications.

Example:
 {0} -p /opt/badasdk/crypto -x appid/Bin/App.exe -t appid/Info/App.htb

Usage:
 {0} [-p path] [-k dev_key] [-d dev_cert] [-c ca_cert] \\
     -a app_path -n app_name [-o output_file]
 {0} -h|--help

{0} expects the following files to be present in the application folder,
specified with the -a option:
 - {{app_path}}/Bin/{{app_name}}.exe  - the application executable file 
 - {{app_path}}/Info/{{app_name}}.htb - the hashtable file
 - {{app_path}}/Info/manifest.xml   - the manifest file

Options:
 -o,  --output-file=fn   Specify output file name. If not specified,
                         standard output is used.
 -a,  --app-path=fn      Specify path to the application folder.
                         In most cases, its last part is the application ID.
 -n,  --app-name=name    Specify application name. This will be used to
                         find executable and hashtable files in the
                         application folder.
 -p,  --crypto-path=path Specify path where {0} will search for
                         default key end certificate file names.
 -k,  --devkey-file=fn   Specify bada development private key file name.
 -d,  --devcert-file=fn  Specify bada development certificate file name.
 -c,  --cacert-file=fn   Specify bada development CA certificate file name.
 -a,  --passphrase=pass  Specify passphrase for the private key.
                         '1111' is used if this option is omitted.'''.format(sys.argv[0])

def main():
	try:	
		opts, args = getopt.getopt(
			sys.argv[1:],
			"ho:a:n:m:p:k:d:c:w:",
			["help", "output=", "app-path=", "app-name=", "crypto-path=", "devkey-file=", "devcert-file=", "cacert-file=", "passphrase="])
	except getopt.GetoptError, err:
		# print help information and exit
		sys.stderr.write('%s: %s\n' % (str(err), sys.argv[0]))
		sys.stderr.write('invoke %s -h to get usage information\n' % sys.argv[0])
		sys.exit(2)

	outputFile = None
	appPath = None
	appName = None
	cryptoPath = None
	devKeyFile = None
	devCertFile = None
	caCertFile = None
	passphrase = '1111'
	for o, a in opts:
		if o in ('-h', '--help'):
			usage()
			sys.exit()
		elif o in ('-o', '--output'):
			outputFile = a
		elif o in ('-a', '--app-path'):
			appPath = a
		elif o in ('-n', '--app-name'):
			appName = a
		elif o in ('-p', '--crypto-path'):
			cryptoPath = a
		elif o in ('-k', '--devkey-file'):
			devKeyFile = a
		elif o in ('-d', '--devcert-file'):
			devCertFile = a
		elif o in ('-c', '--cacert-file'):
			caCertFile = a
		elif o in ('-w', '--passphrase'):
			passphrase = a
		else:
			assert False, 'unhandled option'
	if not cryptoPath is None:
		if not devKeyFile:
			devKeyFile = path.join(cryptoPath, 'badaDevPriKey.pem')
		if not devCertFile:
			devCertFile = path.join(cryptoPath, 'badaDev.cer')
		if not caCertFile:
			caCertFile = path.join(cryptoPath, 'badaCA.cer')
	for f, t in [
		(appPath, "Application path"),
		(appName, "Application name"),
		(devKeyFile, "Private key file"),
		(devCertFile, "Development certificate file"),
		(caCertFile, "CA certificate file")]:
		if f is None:
			sys.stderr.write("%s: %s not specified\n" % (sys.argv[0], t))
			sys.exit(2)

	appFile = path.join(appPath, 'Bin', appName + '.exe')
	htbFile = path.join(appPath, 'Info', appName + '.htb')
	manifestFile = path.join(appPath, 'Info', 'manifest.xml')

	try:
		signer = Signer(devKeyFile, '1111')
		packageSignature = signer.signFiles(appFile, manifestFile)
		appSignature = signer.signFiles(htbFile)
		devcert = stripCertificate(devCertFile)
		cacert = stripCertificate(caCertFile)

		signature = '''<?xml version="1.0"?>
<Signature>
  <FileList>
    <File>{0}</File>
    <File>{1}</File>
  </FileList>
  <certificateChain>
    <certificate>
{2}
    </certificate>
    <certificate>
{3}
    </certificate>
  </certificateChain>
  <SignValue>
    <Package>
{4}
    </Package>
    <AppSignature>
{5}
    </AppSignature>
  </SignValue>
</Signature>
'''.format(
		'/Bin/' + appName + '.exe', '/Info/manifest.xml',
		devcert, cacert, packageSignature, appSignature)

		output = sys.stdout if not outputFile else file(outputFile, 'w')
		output.write(signature)

	except IOError, err:
		sys.stderr.write('%s: %s\n' % (sys.argv[0], str(err)))
		sys.exit(1)

if __name__ == "__main__":
	main()
