#!/usr/bin/env python

# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

# This script is for use by committers.
#
# It should be used in accordance with the project release procedure.
#
# cf. http://wiki.apache.org/couchdb/Release_Procedure

from docutils import core
import sys, os, tempfile

EMAIL_TPL = 'discuss_release.txt'

def red(s):
    return '\033[1;31m%s\033[0m' % s

def get_section(doc_path, version):
	
	version_info = version.split('.')
	if version_info[2] == '0':
		branch = '.'.join(version_info[:2]) + '.x Branch'
		start = lambda x: x.startswith(branch)
		end = lambda x: x.rstrip().endswith('.x Branch')
	else:
		start = lambda x: x.startswith('Version ' + version)
		end = lambda x: x.startswith('Version ')
	
	state, lines = 0, []
	with open(doc_path) as f:
		for ln in f:
			#print state, ln, start(ln), end(ln)
			#raw_input('')
			if state == 0 and start(ln):
				state = 1
			elif state == 1 and end(ln):
				break
			if state:
				lines.append(ln)
	
	if version_info[2] == '0':
		return ''.join(lines[7:]).rstrip()
	else:
		return ''.join(lines[3:]).rstrip()

def main(cache, branch, version):
	
	dir = os.path.dirname(os.path.abspath(__file__))
	with open(os.path.join(dir, EMAIL_TPL)) as f:
		tpl = f.read()

	print red('Parsing documentation')
	changelog_fn = os.path.join(cache, 'branch', branch, 'changelog.rst')
	changelog = get_section(changelog_fn, version)
	
	tpl = tpl.replace('%VERSION%', version)
	tpl = tpl.replace('%CHANGELOG%', changelog)
	print 'Email text:'
	print tpl
	print 'Send the email to: dev@couchdb.apache.org'
	
if __name__ == '__main__':
	
	if len(sys.argv) < 2:
		print 'Usage: discuss_release.py <cache-dir> <branch> <version>'
		sys.exit(0)
	
	if not os.path.isdir(sys.argv[1]):
		print 'error: no cache directory'
		sys.exit(1)
	
	cache = sys.argv[1]
	if len(sys.argv) < 3:
		print 'error: no branch'
		sys.exit(1)
	
	branch = sys.argv[2]
	if len(sys.argv) < 4:
		print 'error: no version'
		sys.exit(1)
	
	version = sys.argv[3]
	main(cache, branch, version)
