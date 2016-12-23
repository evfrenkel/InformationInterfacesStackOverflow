import sys
import csv

locations = {}

with open('locationToCC.csv', 'rb') as p:
	csvReader = csv.DictReader(p, delimiter='|')
	for entry in csvReader:
		if entry['CountryCode'] != None:
			locations[entry['Location']] = entry['CountryCode']
		else:
			print 'None'


outfile = open('countrydata.csv', 'wb')
outfile.write('CountryCode|NumUsers|Ratio|AvgRep|TotalUpVotes|TotalDownVotes|TotalReputation\n')

linenum = 0
totallines = float(647813)

Countries = {}

for loc in locations:
	CountryCode = locations[loc]
	if CountryCode not in Countries:
		Countries[CountryCode] = {}
		Countries[CountryCode]['NumUsers'] =  0
		Countries[CountryCode]['TotalUpVotes'] = 0
		Countries[CountryCode]['TotalDownVotes'] = 0
		Countries[CountryCode]['TotalReputation'] = 0
		#Countries[CountryCode]['AvgAge'] = 0

with open("users.csv", 'rb') as infile:
	csvReader = csv.DictReader(infile)
	for entry in csvReader:
		linenum = linenum + 1
		percent = float(linenum)/totallines
		loc = entry['Location']
		if loc in locations:
			#UpVotes DownVotes, Reputation
			CountryCode = locations[loc]
			UpVotes = entry['UpVotes']
			DownVotes = entry['DownVotes']
			#Age = entry['Age']
			Reputation = entry['Reputation']
			
			Countries[CountryCode]['NumUsers'] += 1
			Countries[CountryCode]['TotalUpVotes'] += int(UpVotes)
			Countries[CountryCode]['TotalDownVotes'] += int(DownVotes)
			Countries[CountryCode]['TotalReputation'] += int(Reputation)
			#Countries[CountryCode]['AvgAge'] += Age
			
			#print percent

for CountryCode in Countries:
	if len(CountryCode) < 3:
		if Countries[CountryCode]['TotalDownVotes'] > 0:
			Ratio = int(round(float(Countries[CountryCode]['TotalUpVotes'])/float(Countries[CountryCode]['TotalDownVotes'])))
		else:
			Ratio = 1
		if Countries[CountryCode]['TotalReputation'] > 0:
			AvgRep = int(round(float(Countries[CountryCode]['TotalReputation'])/float(Countries[CountryCode]['NumUsers'])))
		else:
			AvgRep = 0
		line =  CountryCode + '|' + \
				str(Countries[CountryCode]['NumUsers']) + '|' + \
				str(Ratio) + '|' + \
				str(AvgRep) + '|' + \
				str(Countries[CountryCode]['TotalUpVotes']) + '|' + \
				str(Countries[CountryCode]['TotalDownVotes']) + '|' + \
				str(Countries[CountryCode]['TotalReputation']) + '\n'
				#Countries[CountryCode]['AvgAge'] + '\n'
			   
		outfile.write(line)
			




