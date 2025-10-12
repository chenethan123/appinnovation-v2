"""
Scrape AP Course Units from College Board
This script extracts unit information for all AP courses
"""

import json
import requests
from bs4 import BeautifulSoup
import time

# AP Courses with their College Board URLs
AP_COURSES = {
    "AP Calculus AB": "https://apstudents.collegeboard.org/courses/ap-calculus-ab",
    "AP Calculus BC": "https://apstudents.collegeboard.org/courses/ap-calculus-bc",
    "AP Statistics": "https://apstudents.collegeboard.org/courses/ap-statistics",
    "AP Computer Science A": "https://apstudents.collegeboard.org/courses/ap-computer-science-a",
    "AP Computer Science Principles": "https://apstudents.collegeboard.org/courses/ap-computer-science-principles",
    "AP Physics 1": "https://apstudents.collegeboard.org/courses/ap-physics-1",
    "AP Physics 2": "https://apstudents.collegeboard.org/courses/ap-physics-2",
    "AP Physics C: Mechanics": "https://apstudents.collegeboard.org/courses/ap-physics-c-mechanics",
    "AP Physics C: Electricity and Magnetism": "https://apstudents.collegeboard.org/courses/ap-physics-c-electricity-and-magnetism",
    "AP Chemistry": "https://apstudents.collegeboard.org/courses/ap-chemistry",
    "AP Biology": "https://apstudents.collegeboard.org/courses/ap-biology",
    "AP Environmental Science": "https://apstudents.collegeboard.org/courses/ap-environmental-science",
    "AP Psychology": "https://apstudents.collegeboard.org/courses/ap-psychology",
    "AP Microeconomics": "https://apstudents.collegeboard.org/courses/ap-microeconomics",
    "AP Macroeconomics": "https://apstudents.collegeboard.org/courses/ap-macroeconomics",
    "AP United States History": "https://apstudents.collegeboard.org/courses/ap-united-states-history",
    "AP World History: Modern": "https://apstudents.collegeboard.org/courses/ap-world-history-modern",
    "AP European History": "https://apstudents.collegeboard.org/courses/ap-european-history",
    "AP United States Government and Politics": "https://apstudents.collegeboard.org/courses/ap-united-states-government-and-politics",
    "AP Comparative Government and Politics": "https://apstudents.collegeboard.org/courses/ap-comparative-government-and-politics",
    "AP English Language and Composition": "https://apstudents.collegeboard.org/courses/ap-english-language-and-composition",
    "AP English Literature and Composition": "https://apstudents.collegeboard.org/courses/ap-english-literature-and-composition",
    "AP Spanish Language and Culture": "https://apstudents.collegeboard.org/courses/ap-spanish-language-and-culture",
    "AP French Language and Culture": "https://apstudents.collegeboard.org/courses/ap-french-language-and-culture",
    "AP Chinese Language and Culture": "https://apstudents.collegeboard.org/courses/ap-chinese-language-and-culture",
    "AP Human Geography": "https://apstudents.collegeboard.org/courses/ap-human-geography",
    "AP Art History": "https://apstudents.collegeboard.org/courses/ap-art-history",
    "AP Music Theory": "https://apstudents.collegeboard.org/courses/ap-music-theory",
}

def scrape_ap_units(course_name, url):
    """Scrape units from a College Board AP course page"""
    print(f"Scraping {course_name}...")
    
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        }
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        units = []
        
        # Try multiple selectors for unit information
        # College Board uses various HTML structures
        
        # Method 1: Look for unit headings
        unit_sections = soup.find_all(['h2', 'h3'], string=lambda text: text and 'Unit' in text)
        
        for i, section in enumerate(unit_sections, 1):
            unit_text = section.get_text().strip()
            # Extract unit name
            if ':' in unit_text:
                unit_name = unit_text.split(':', 1)[1].strip()
            else:
                unit_name = unit_text
                
            # Try to find description
            description = ""
            next_elem = section.find_next_sibling()
            if next_elem and next_elem.name == 'p':
                description = next_elem.get_text().strip()[:200]  # Limit length
            
            units.append({
                "order_index": i,
                "name": unit_name,
                "description": description or f"Topics and concepts for {unit_name}"
            })
        
        # Method 2: If no units found, try accordion/collapsible sections
        if not units:
            accordions = soup.find_all(['div', 'section'], class_=lambda c: c and ('unit' in c.lower() or 'accordion' in c.lower()))
            for i, accordion in enumerate(accordions[:10], 1):  # Limit to 10 units
                heading = accordion.find(['h2', 'h3', 'h4'])
                if heading:
                    unit_text = heading.get_text().strip()
                    units.append({
                        "order_index": i,
                        "name": unit_text,
                        "description": f"Core content for {unit_text}"
                    })
        
        # Fallback: Generic units if nothing found
        if not units:
            print(f"  ⚠️  No units found via scraping for {course_name}, using generic structure")
            return get_default_ap_units(course_name)
        
        print(f"  ✅ Found {len(units)} units")
        return units
        
    except Exception as e:
        print(f"  ❌ Error scraping {course_name}: {e}")
        return get_default_ap_units(course_name)

def get_default_ap_units(course_name):
    """Return default unit structure if scraping fails"""
    # Most AP courses have 7-10 units
    num_units = 8
    
    return [
        {
            "order_index": i,
            "name": f"Unit {i}",
            "description": f"Core concepts and skills for Unit {i} of {course_name}"
        }
        for i in range(1, num_units + 1)
    ]

def main():
    all_units = {}
    
    for course_name, url in AP_COURSES.items():
        units = scrape_ap_units(course_name, url)
        all_units[course_name] = units
        time.sleep(1)  # Be respectful with rate limiting
    
    # Save to JSON
    output_file = '../data/ap_course_units.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(all_units, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Saved units for {len(all_units)} AP courses to {output_file}")
    
    # Print summary
    print("\n📊 Summary:")
    for course, units in all_units.items():
        print(f"  {course}: {len(units)} units")

if __name__ == "__main__":
    main()
