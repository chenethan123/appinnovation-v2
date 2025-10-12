#!/usr/bin/env python3
import json

# Read the courses JSON
with open('assets/courses.json', 'r') as f:
    data = json.load(f)

# Define unique IDs for each AP course
ap_course_ids = {
    "AP Calculus AB": "AP-CALC-AB",
    "AP Calculus BC": "AP-CALC-BC",
    "AP Statistics": "AP-STAT",
    "AP Computer Science A": "AP-CS-A",
    "AP Computer Science Principles": "AP-CS-P",
    "AP Physics 1": "AP-PHYS-1",
    "AP Physics 2": "AP-PHYS-2",
    "AP Physics C: Mechanics": "AP-PHYS-C-MECH",
    "AP Physics C: Electricity and Magnetism": "AP-PHYS-C-EM",
    "AP Chemistry": "AP-CHEM",
    "AP Biology": "AP-BIO",
    "AP Environmental Science": "AP-ENVIRO",
    "AP English Language and Composition": "AP-ENG-LANG",
    "AP English Literature and Composition": "AP-ENG-LIT",
    "AP United States History": "AP-USHIST",
    "AP World History: Modern": "AP-WHIST",
    "AP European History": "AP-EUROHIST",
    "AP Art History": "AP-ARTHIST",
    "AP Music Theory": "AP-MUSIC",
    "AP Psychology": "AP-PSYCH",
    "AP Microeconomics": "AP-MICRO",
    "AP Macroeconomics": "AP-MACRO",
    "AP United States Government and Politics": "AP-USGOV",
    "AP Comparative Government and Politics": "AP-COMPGOV",
    "AP Human Geography": "AP-HUMGEO",
    "AP Spanish Language and Culture": "AP-SPAN-LANG",
    "AP Spanish Literature and Culture": "AP-SPAN-LIT",
    "AP French Language and Culture": "AP-FREN",
    "AP German Language and Culture": "AP-GERM",
    "AP Chinese Language and Culture": "AP-CHIN",
    "AP Italian Language and Culture": "AP-ITAL",
    "AP Japanese Language and Culture": "AP-JAPN",
    "AP Latin": "AP-LATIN"
}

# Update course IDs
for course in data['courses']:
    if course['subjectName'] in ap_course_ids:
        course['courseId'] = ap_course_ids[course['subjectName']]

# Write back
with open('assets/courses.json', 'w') as f:
    json.dump(data, f, indent=2)

print(f"✅ Updated {len([c for c in data['courses'] if c['courseId'].startswith('AP-')])} AP courses with unique IDs")
