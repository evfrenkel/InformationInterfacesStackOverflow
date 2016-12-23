import sys
import csv
from pygeocoder import Geocoder


locations = {}

with open('countryinfo.csv', 'rb') as p:
	csvReader = csv.DictReader(p, delimiter='|')
	for entry in csvReader:
		locations[entry['Location']] = 0
		print entry['Location']


outfile = open('countryinfo.csv', 'ab') # ab = append
#outfile.write('Location|CountryCode|CountryName\n')

linenum = 0
totallines = 647813

with open("users.csv", 'rb') as infile:
	csvReader = csv.DictReader(infile)
	for entry in csvReader:
		linenum = linenum + 1
		percent = float(linenum)/float(totallines)
		if entry['Location'] not in locations:
			locations[entry['Location']] = 0
			newEntry = {}
			
			print entry['Location']
			
			try:
				place = Geocoder.geocode(entry['Location'])
			except:
				print str(sys.exc_info())
				print percent
				print '-------------------------------'
				continue
		
			newEntry['Location'] = entry['Location'].decode('utf-8')
			#print newEntry['Location']
			newEntry['CountryCode'] = place.country__short_name
			#print newEntry['CountryCode']
			newEntry['CountryName'] = place.country
			#print newEntry['CountryName']
			
			if newEntry['CountryCode'] != None and newEntry['CountryName'] != None:
				line = newEntry['Location'] + '|' + \
					   newEntry['CountryCode'] + '|' + \
					   newEntry['CountryName'] + '\n'
				   
				line = line.encode("utf-8")
			
				print line
				print percent
				print '-------------------------------'
			
				outfile.write(line)
			




