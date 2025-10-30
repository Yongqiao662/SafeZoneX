// Test file to verify location processing fixes
// Run this in Dart console to test the _getCleanLocationName function

void main() {
  // Test cases for location name extraction
  testLocationExtraction();
}

void testLocationExtraction() {
  print('🧪 Testing location name extraction...\n');
  
  // Test cases
  List<Map<String, String>> testCases = [
    {
      'input': 'Current Location: Faculty of Engineering (120m away)',
      'expected': 'Faculty of Engineering',
      'description': 'GPS location with distance'
    },
    {
      'input': 'Current Location: Chancellory (45m away)',
      'expected': 'Chancellory',
      'description': 'GPS location with short distance'
    },
    {
      'input': 'Faculty of Science',
      'expected': 'Faculty of Science',
      'description': 'Manually selected location'
    },
    {
      'input': 'Library',
      'expected': 'Library',
      'description': 'Simple manual selection'
    },
    {
      'input': 'Current Location: Sports Complex',
      'expected': 'Sports Complex',
      'description': 'GPS location without distance info'
    }
  ];
  
  for (var testCase in testCases) {
    String result = getCleanLocationName(testCase['input']!);
    bool passed = result == testCase['expected'];
    
    print('${passed ? "✅" : "❌"} ${testCase['description']}');
    print('   Input: "${testCase['input']}"');
    print('   Expected: "${testCase['expected']}"');
    print('   Got: "$result"');
    print('');
  }
}

String getCleanLocationName(String selectedLocation) {
  // If it's a GPS location with "Current Location:" prefix
  if (selectedLocation.startsWith("Current Location:")) {
    String locationPart = selectedLocation.replaceFirst("Current Location: ", "");
    // Extract just the location name before the distance info
    int distanceIndex = locationPart.indexOf(' (');
    if (distanceIndex != -1) {
      return locationPart.substring(0, distanceIndex);
    }
    return locationPart;
  }
  
  // If it's a manually selected location, return as is
  return selectedLocation;
}