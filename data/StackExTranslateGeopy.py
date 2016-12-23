import sys
import csv
from geopy import geocoders

locations = {}

with open('countryinfo.csv', 'rb') as p:
	csvReader = csv.DictReader(p, delimiter='|')
	for entry in csvReader:
		locations[entry['Location']] = 0


#coveredlocs = open('coveredlocs.txt', 'ab')

outfile = open('countryinfo.csv', 'ab') # ab = append

gn = geocoders.GeoNames(country_bias=None, username='telahoo')

linenum = 0
totallines = float(647813)

with open("users.csv", 'rb') as infile:
	csvReader = csv.DictReader(infile)
	for entry in csvReader:
		linenum = linenum + 1
		percent = float(linenum)/totallines
		loc = entry['Location']
		if loc not in locations and linenum > 615422:
			#coveredlocs.write(loc + '\n')  ##str(loc)
			locations[loc] = 0
			newEntry = {}
			
			print loc
			
			try:
				place, (lat, lng) = gn.geocode(loc)
			except:
				print str(sys.exc_info())
				print percent
				print '-------------------------------'
				continue
		
			print place
			place = place.split(', ')
			
			
			newEntry['Location'] = loc.decode('utf-8')
			try:
				newEntry['CountryCode'] = place[2]
			except:
				print str(sys.exc_info())
				print percent
				print '-------------------------------'
				continue
			newEntry['CountryName'] = 'none'

			line = newEntry['Location'] + '|' + \
				   newEntry['CountryCode'] + '|' + \
				   newEntry['CountryName'] + '\n'
			   
			line = line.encode("utf-8")
		
			print line
			print percent
			print '-------------------------------'
		
			outfile.write(line)
			




