class APSubject {
  final String name;
  final String description;
  final String category;
  final String color;
  final List<String> keywords;

  const APSubject({
    required this.name,
    required this.description,
    required this.category,
    required this.color,
    required this.keywords,
  });
}

class APSubjects {
  static const List<APSubject> allSubjects = [
    // Mathematics
    APSubject(
      name: 'AP Calculus AB',
      description: 'Differential and integral calculus concepts',
      category: 'Mathematics',
      color: '#2196F3',
      keywords: ['calculus', 'derivatives', 'integrals', 'limits', 'math'],
    ),
    APSubject(
      name: 'AP Calculus BC',
      description: 'Advanced calculus including series and parametric equations',
      category: 'Mathematics',
      color: '#1976D2',
      keywords: ['calculus', 'series', 'parametric', 'polar', 'advanced math'],
    ),
    APSubject(
      name: 'AP Statistics',
      description: 'Statistical analysis and probability',
      category: 'Mathematics',
      color: '#0D47A1',
      keywords: ['statistics', 'probability', 'data analysis', 'regression'],
    ),
    APSubject(
      name: 'AP Precalculus',
      description: 'Functions, trigonometry, and algebraic concepts',
      category: 'Mathematics',
      color: '#42A5F5',
      keywords: ['precalculus', 'functions', 'trigonometry', 'algebra'],
    ),

    // Sciences
    APSubject(
      name: 'AP Physics 1',
      description: 'Algebra-based introductory physics',
      category: 'Science',
      color: '#4CAF50',
      keywords: ['physics', 'mechanics', 'waves', 'algebra-based'],
    ),
    APSubject(
      name: 'AP Physics 2',
      description: 'Algebra-based physics: fluids, thermodynamics, electricity',
      category: 'Science',
      color: '#388E3C',
      keywords: ['physics', 'fluids', 'thermodynamics', 'electricity', 'magnetism'],
    ),
    APSubject(
      name: 'AP Physics C: Mechanics',
      description: 'Calculus-based mechanics',
      category: 'Science',
      color: '#2E7D32',
      keywords: ['physics', 'mechanics', 'calculus-based', 'kinematics', 'dynamics'],
    ),
    APSubject(
      name: 'AP Physics C: Electricity and Magnetism',
      description: 'Calculus-based electricity and magnetism',
      category: 'Science',
      color: '#1B5E20',
      keywords: ['physics', 'electricity', 'magnetism', 'calculus-based', 'circuits'],
    ),
    APSubject(
      name: 'AP Chemistry',
      description: 'Chemical reactions, bonding, and laboratory techniques',
      category: 'Science',
      color: '#FF9800',
      keywords: ['chemistry', 'reactions', 'bonding', 'stoichiometry', 'lab'],
    ),
    APSubject(
      name: 'AP Biology',
      description: 'Molecular biology, genetics, evolution, and ecology',
      category: 'Science',
      color: '#8BC34A',
      keywords: ['biology', 'genetics', 'evolution', 'ecology', 'molecular'],
    ),
    APSubject(
      name: 'AP Environmental Science',
      description: 'Environmental systems and human impact',
      category: 'Science',
      color: '#689F38',
      keywords: ['environment', 'ecology', 'sustainability', 'climate'],
    ),

    // English
    APSubject(
      name: 'AP English Language and Composition',
      description: 'Rhetorical analysis and argumentative writing',
      category: 'English',
      color: '#9C27B0',
      keywords: ['english', 'rhetoric', 'composition', 'writing', 'analysis'],
    ),
    APSubject(
      name: 'AP English Literature and Composition',
      description: 'Literary analysis and critical writing',
      category: 'English',
      color: '#7B1FA2',
      keywords: ['english', 'literature', 'poetry', 'prose', 'analysis'],
    ),

    // History and Social Sciences
    APSubject(
      name: 'AP United States History',
      description: 'American history from pre-Columbian to present',
      category: 'History',
      color: '#F44336',
      keywords: ['history', 'american', 'united states', 'apush'],
    ),
    APSubject(
      name: 'AP World History: Modern',
      description: 'Global history from 1200 CE to present',
      category: 'History',
      color: '#D32F2F',
      keywords: ['history', 'world', 'global', 'modern'],
    ),
    APSubject(
      name: 'AP European History',
      description: 'European history from Renaissance to present',
      category: 'History',
      color: '#C62828',
      keywords: ['history', 'european', 'renaissance', 'modern europe'],
    ),
    APSubject(
      name: 'AP Government and Politics',
      description: 'American government and political systems',
      category: 'Social Science',
      color: '#E91E63',
      keywords: ['government', 'politics', 'constitution', 'democracy'],
    ),
    APSubject(
      name: 'AP Comparative Government and Politics',
      description: 'Comparative analysis of political systems',
      category: 'Social Science',
      color: '#AD1457',
      keywords: ['government', 'politics', 'comparative', 'international'],
    ),
    APSubject(
      name: 'AP Psychology',
      description: 'Psychological concepts and research methods',
      category: 'Social Science',
      color: '#673AB7',
      keywords: ['psychology', 'behavior', 'cognition', 'research'],
    ),
    APSubject(
      name: 'AP Human Geography',
      description: 'Spatial patterns and human-environment interactions',
      category: 'Social Science',
      color: '#3F51B5',
      keywords: ['geography', 'human', 'spatial', 'environment'],
    ),
    APSubject(
      name: 'AP Economics (Macro)',
      description: 'Macroeconomic principles and policies',
      category: 'Social Science',
      color: '#009688',
      keywords: ['economics', 'macro', 'policy', 'markets'],
    ),
    APSubject(
      name: 'AP Economics (Micro)',
      description: 'Microeconomic principles and market behavior',
      category: 'Social Science',
      color: '#00796B',
      keywords: ['economics', 'micro', 'markets', 'supply', 'demand'],
    ),

    // Computer Science
    APSubject(
      name: 'AP Computer Science A',
      description: 'Java programming and object-oriented design',
      category: 'Computer Science',
      color: '#607D8B',
      keywords: ['computer science', 'java', 'programming', 'algorithms'],
    ),
    APSubject(
      name: 'AP Computer Science Principles',
      description: 'Computational thinking and digital citizenship',
      category: 'Computer Science',
      color: '#455A64',
      keywords: ['computer science', 'computational thinking', 'digital'],
    ),

    // Languages
    APSubject(
      name: 'AP Spanish Language and Culture',
      description: 'Spanish language proficiency and cultural understanding',
      category: 'World Languages',
      color: '#FF5722',
      keywords: ['spanish', 'language', 'culture', 'communication'],
    ),
    APSubject(
      name: 'AP Spanish Literature and Culture',
      description: 'Spanish and Latin American literature',
      category: 'World Languages',
      color: '#E64A19',
      keywords: ['spanish', 'literature', 'culture', 'latin american'],
    ),
    APSubject(
      name: 'AP French Language and Culture',
      description: 'French language proficiency and cultural understanding',
      category: 'World Languages',
      color: '#3F51B5',
      keywords: ['french', 'language', 'culture', 'francophone'],
    ),
    APSubject(
      name: 'AP German Language and Culture',
      description: 'German language proficiency and cultural understanding',
      category: 'World Languages',
      color: '#795548',
      keywords: ['german', 'language', 'culture', 'deutschland'],
    ),
    APSubject(
      name: 'AP Chinese Language and Culture',
      description: 'Chinese language proficiency and cultural understanding',
      category: 'World Languages',
      color: '#F44336',
      keywords: ['chinese', 'mandarin', 'language', 'culture'],
    ),
    APSubject(
      name: 'AP Japanese Language and Culture',
      description: 'Japanese language proficiency and cultural understanding',
      category: 'World Languages',
      color: '#E91E63',
      keywords: ['japanese', 'language', 'culture', 'nihongo'],
    ),
    APSubject(
      name: 'AP Latin',
      description: 'Latin language and Roman culture',
      category: 'World Languages',
      color: '#9C27B0',
      keywords: ['latin', 'roman', 'classical', 'ancient'],
    ),

    // Arts
    APSubject(
      name: 'AP Art and Design: 2-D',
      description: '2-D art and design portfolio development',
      category: 'Arts',
      color: '#E91E63',
      keywords: ['art', 'design', '2d', 'portfolio', 'visual'],
    ),
    APSubject(
      name: 'AP Art and Design: 3-D',
      description: '3-D art and design portfolio development',
      category: 'Arts',
      color: '#9C27B0',
      keywords: ['art', 'design', '3d', 'sculpture', 'portfolio'],
    ),
    APSubject(
      name: 'AP Art and Design: Drawing',
      description: 'Drawing portfolio development',
      category: 'Arts',
      color: '#673AB7',
      keywords: ['art', 'drawing', 'portfolio', 'visual', 'sketch'],
    ),
    APSubject(
      name: 'AP Music Theory',
      description: 'Music composition, analysis, and aural skills',
      category: 'Arts',
      color: '#3F51B5',
      keywords: ['music', 'theory', 'composition', 'harmony', 'analysis'],
    ),
  ];

  static List<APSubject> searchSubjects(String query) {
    if (query.isEmpty) return allSubjects;
    
    final lowercaseQuery = query.toLowerCase();
    return allSubjects.where((subject) {
      return subject.name.toLowerCase().contains(lowercaseQuery) ||
             subject.description.toLowerCase().contains(lowercaseQuery) ||
             subject.category.toLowerCase().contains(lowercaseQuery) ||
             subject.keywords.any((keyword) => keyword.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  static List<APSubject> getSubjectsByCategory(String category) {
    return allSubjects.where((subject) => subject.category == category).toList();
  }

  static List<String> getAllCategories() {
    return allSubjects.map((subject) => subject.category).toSet().toList()..sort();
  }
}
