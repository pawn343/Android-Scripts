#!/usr/bin/python2

'''
Small script to auto force stop unused app activity/proc.
Tested on jellybean.
'''

import os, re


__author__ = 'bluesec7'
__site__ = 'https://kagurasuki.blogspot.com'

# protect your apps proc from being killed
protect = ['com.google.android.gms.persistent',
#'yarolegovich.materialterminal',
'com.android.vending.billing.InAppBillingService.COIN',
'org.pocketworkstation.pckeyboard',
'com.google.android.gms',
#'com.android.vending',
'com.internet.speed.meter.lite',
]

def recent():
	'get recent apps'
	method_1 = "dumpsys window tokens|grep 'App #'"
	method_2 = "dumpsys activity activities|grep \"Hist #\""
	method_3 = "dumpsys window tokens|grep \"AppWindowToken\""
	return re.findall('[a-zA-Z_0-9\.]+/', os.popen(method_2).read())

def activities():
	'get all activities'
	method_1 = "dumpsys activity|grep \"Proc #\""
	return os.popen(method_1).read()
	

def stop_activities():
	states = {'\(service\)':(('adj=vis', '/FS'), ('adj=prcp', '/F')),
	'\(started\-services\)':(('adj=svc ', '/B'), ('adj=svcb', '/B')),
	'\(fg\-service\)':(('adj=prcp', '/FS')),
	#'\(bg\-empty\)':(('adj=bak', '/F', 'adj=bak', '/B')),
	}
	services = {}
	for proc in activities().splitlines():
		ppkg = re.search('[0-9]+\:[a-zA-Z_0-9\.]+(\:[a-zA-Z_0-9]+)?', proc)
		#print ppkg.group()
		for state in states:
			m = re.search(state, proc, re.M)
			if m:
				#print m.group(),'in', proc
				for t in states[state]:
					if t[0] in proc and t[1] in proc:
						#print 'kill', ppkg.group()
						s = ppkg.group().split(':')
						if not services.has_key(s[1]):
							services[s[1]] = []
						if len(s)==3:
							services[s[1]].append(s[2])
						break
				break
	#print services
	# step to check activities
	kill_queue = []
	for s in services:
		meminfo = os.popen('dumpsys meminfo %s'%s).read()
		m = re.search('Activities\:([\s]+)?[0-1]', meminfo)
		if m:
			#print 'proc for %s'%s
			if '1' in m.group():
				if s not in recent():
					# stop proc
					#print 'active proc but not in recent: %s'%s
					#kill_queue.append(s)
					pass
			else:
				#print 'not an active proc: %s'%s
				# stop proc
				kill_queue.append(s)
				
		else:
			#print 'no proc found for %s'%s
			if services[s]:
				#print 'sub services stopped: %s'%', '.join(services[s])
				# stop proc
				kill_queue.append(s)
			else:
				pass
				#print 'no sub services found: %s'%s 
	for q in kill_queue:
		if q not in protect:
			print os.popen('am force-stop %s'%q).read()
	#print recent()
			


if __name__=='__main__':
	while 1:
			stop_activities()
