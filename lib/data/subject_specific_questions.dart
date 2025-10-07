import '../models/question.dart';

class SubjectSpecificQuestions {
  static const Map<String, List<Map<String, dynamic>>> questionsBySubject = {
    // AP Chinese Language and Culture
    'AP Chinese Language and Culture': [
      {
        'question': '你好 means:',
        'options': ['Goodbye', 'Hello', 'Thank you', 'Please'],
        'correct': 'Hello',
        'explanation': '你好 (nǐ hǎo) is the standard greeting meaning "hello" in Chinese.',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the correct pinyin for 学生?',
        'options': ['xuéshēng', 'xiáoshēng', 'xuéshèng', 'xiáoshèng'],
        'correct': 'xuéshēng',
        'explanation': '学生 (xuéshēng) means "student" in Chinese.',
        'difficulty': 'medium',
      },
      {
        'question': 'Which character means "water"?',
        'options': ['火', '水', '土', '木'],
        'correct': '水',
        'explanation': '水 (shuǐ) is the Chinese character for water.',
        'difficulty': 'easy',
      },
      {
        'question': 'Complete the sentence: 我___中文。(I speak Chinese)',
        'options': ['说', '听', '看', '写'],
        'correct': '说',
        'explanation': '说 (shuō) means "to speak". 我说中文 means "I speak Chinese".',
        'difficulty': 'medium',
      },
      {
        'question': 'What does 谢谢 mean?',
        'options': ['Sorry', 'Excuse me', 'Thank you', 'You\'re welcome'],
        'correct': 'Thank you',
        'explanation': '谢谢 (xiè xiè) means "thank you" in Chinese.',
        'difficulty': 'easy',
      },
    ],

    // AP Physics 1 (Algebra-based, no calculus)
    'AP Physics 1': [
      {
        'question': 'A ball is thrown horizontally from a cliff. What is true about its motion?',
        'options': [
          'Horizontal velocity remains constant',
          'Vertical velocity remains constant', 
          'Both velocities remain constant',
          'Both velocities change at the same rate'
        ],
        'correct': 'Horizontal velocity remains constant',
        'explanation': 'In projectile motion, horizontal velocity is constant (ignoring air resistance), while vertical velocity changes due to gravity.',
        'difficulty': 'medium',
      },
      {
        'question': 'What is Newton\'s second law?',
        'options': ['F = ma', 'F = mv', 'F = mg', 'F = kx'],
        'correct': 'F = ma',
        'explanation': 'Newton\'s second law states that Force equals mass times acceleration (F = ma).',
        'difficulty': 'easy',
      },
      {
        'question': 'A 2 kg object accelerates at 3 m/s². What is the net force?',
        'options': ['5 N', '6 N', '1.5 N', '0.67 N'],
        'correct': '6 N',
        'explanation': 'Using F = ma: F = 2 kg × 3 m/s² = 6 N',
        'difficulty': 'easy',
      },
      {
        'question': 'What happens to kinetic energy when speed doubles?',
        'options': ['Doubles', 'Triples', 'Quadruples', 'Stays the same'],
        'correct': 'Quadruples',
        'explanation': 'KE = ½mv². When v doubles, v² becomes 4 times larger, so KE quadruples.',
        'difficulty': 'medium',
      },
      {
        'question': 'Two objects collide and stick together. What is conserved?',
        'options': ['Kinetic energy only', 'Momentum only', 'Both momentum and kinetic energy', 'Neither'],
        'correct': 'Momentum only',
        'explanation': 'In inelastic collisions, momentum is conserved but kinetic energy is not.',
        'difficulty': 'medium',
      },
    ],

    // AP Physics C (Calculus-based)
    'AP Physics C: Mechanics': [
      {
        'question': 'If position is x(t) = 3t² + 2t, what is the acceleration?',
        'options': ['6t + 2', '6t', '6', '3t + 2'],
        'correct': '6',
        'explanation': 'v(t) = dx/dt = 6t + 2, then a(t) = dv/dt = 6',
        'difficulty': 'medium',
      },
      {
        'question': 'What is the moment of inertia of a solid sphere about its center?',
        'options': ['(1/2)MR²', '(2/5)MR²', 'MR²', '(1/3)MR²'],
        'correct': '(2/5)MR²',
        'explanation': 'For a solid sphere rotating about its center, I = (2/5)MR²',
        'difficulty': 'hard',
      },
      {
        'question': 'If F(x) = -kx, what type of motion results?',
        'options': ['Linear motion', 'Circular motion', 'Simple harmonic motion', 'Projectile motion'],
        'correct': 'Simple harmonic motion',
        'explanation': 'F = -kx is Hooke\'s law, which produces simple harmonic motion.',
        'difficulty': 'medium',
      },
    ],

    // AP Spanish Language and Culture
    'AP Spanish Language and Culture': [
      {
        'question': '¿Cómo se dice "hello" en español?',
        'options': ['Adiós', 'Hola', 'Gracias', 'Por favor'],
        'correct': 'Hola',
        'explanation': '"Hola" means "hello" in Spanish.',
        'difficulty': 'easy',
      },
      {
        'question': 'Complete: Yo _____ estudiante.',
        'options': ['es', 'soy', 'está', 'son'],
        'correct': 'soy',
        'explanation': '"Soy" is the first person singular form of "ser" (to be).',
        'difficulty': 'easy',
      },
      {
        'question': '¿Cuál es el plural de "libro"?',
        'options': ['libros', 'libras', 'libroes', 'libro'],
        'correct': 'libros',
        'explanation': 'The plural of "libro" (book) is "libros" (books).',
        'difficulty': 'easy',
      },
      {
        'question': 'What does "Me gusta" mean?',
        'options': ['I need', 'I want', 'I like', 'I have'],
        'correct': 'I like',
        'explanation': '"Me gusta" means "I like" in Spanish.',
        'difficulty': 'easy',
      },
    ],

    // AP French Language and Culture
    'AP French Language and Culture': [
      {
        'question': 'Comment dit-on "hello" en français?',
        'options': ['Au revoir', 'Bonjour', 'Merci', 'S\'il vous plaît'],
        'correct': 'Bonjour',
        'explanation': '"Bonjour" means "hello" or "good day" in French.',
        'difficulty': 'easy',
      },
      {
        'question': 'Complete: Je _____ étudiant.',
        'options': ['es', 'suis', 'est', 'sont'],
        'correct': 'suis',
        'explanation': '"Suis" is the first person singular form of "être" (to be).',
        'difficulty': 'easy',
      },
      {
        'question': 'What does "J\'aime" mean?',
        'options': ['I need', 'I want', 'I like/love', 'I have'],
        'correct': 'I like/love',
        'explanation': '"J\'aime" means "I like" or "I love" in French.',
        'difficulty': 'easy',
      },
    ],

    // AP Calculus AB (Calculus questions)
    'AP Calculus AB': [
      {
        'question': 'What is the derivative of f(x) = x³ + 2x² - 5x + 1?',
        'options': ['3x² + 4x - 5', '3x² + 4x + 5', 'x² + 4x - 5', '3x² - 4x - 5'],
        'correct': '3x² + 4x - 5',
        'explanation': 'Using the power rule: d/dx[x³] = 3x², d/dx[2x²] = 4x, d/dx[-5x] = -5, d/dx[1] = 0',
        'difficulty': 'medium',
      },
      {
        'question': 'Find the limit: lim(x→0) (sin x)/x',
        'options': ['0', '1', '∞', 'undefined'],
        'correct': '1',
        'explanation': 'This is a fundamental limit in calculus. lim(x→0) (sin x)/x = 1',
        'difficulty': 'medium',
      },
      {
        'question': 'What is ∫ 2x dx?',
        'options': ['x² + C', '2x² + C', 'x²', '2x'],
        'correct': 'x² + C',
        'explanation': 'Using the power rule for integration: ∫ 2x dx = 2 · (x²/2) + C = x² + C',
        'difficulty': 'easy',
      },
    ],

    // AP Chemistry
    'AP Chemistry': [
      {
        'question': 'What is the electron configuration of oxygen?',
        'options': ['1s² 2s² 2p⁴', '1s² 2s² 2p⁶', '1s² 2s² 2p²', '1s² 2s⁴'],
        'correct': '1s² 2s² 2p⁴',
        'explanation': 'Oxygen has 8 electrons: 2 in 1s, 2 in 2s, and 4 in 2p orbitals',
        'difficulty': 'medium',
      },
      {
        'question': 'What is Avogadro\'s number?',
        'options': ['6.022 × 10²³', '6.022 × 10²²', '6.022 × 10²⁴', '6.022 × 10²¹'],
        'correct': '6.022 × 10²³',
        'explanation': 'Avogadro\'s number is approximately 6.022 × 10²³ particles per mole',
        'difficulty': 'medium',
      },
      {
        'question': 'What is the chemical symbol for gold?',
        'options': ['Go', 'Gd', 'Au', 'Ag'],
        'correct': 'Au',
        'explanation': 'Gold\'s chemical symbol is Au, from the Latin word "aurum"',
        'difficulty': 'easy',
      },
    ],

    // AP Biology
    'AP Biology': [
      {
        'question': 'What is the powerhouse of the cell?',
        'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Endoplasmic reticulum'],
        'correct': 'Mitochondria',
        'explanation': 'Mitochondria produce ATP, the energy currency of cells',
        'difficulty': 'easy',
      },
      {
        'question': 'Which process occurs in the mitochondrial matrix?',
        'options': ['Glycolysis', 'Krebs cycle', 'Electron transport', 'Fermentation'],
        'correct': 'Krebs cycle',
        'explanation': 'The Krebs cycle (citric acid cycle) occurs in the mitochondrial matrix',
        'difficulty': 'medium',
      },
      {
        'question': 'What is the process by which plants make food?',
        'options': ['Respiration', 'Photosynthesis', 'Digestion', 'Fermentation'],
        'correct': 'Photosynthesis',
        'explanation': 'Photosynthesis converts light energy into chemical energy (glucose)',
        'difficulty': 'easy',
      },
    ],

    // AP Computer Science A
    'AP Computer Science A': [
      {
        'question': 'What is the time complexity of binary search?',
        'options': ['O(n)', 'O(log n)', 'O(n²)', 'O(1)'],
        'correct': 'O(log n)',
        'explanation': 'Binary search eliminates half the search space each iteration',
        'difficulty': 'medium',
      },
      {
        'question': 'Which data structure follows LIFO (Last In, First Out)?',
        'options': ['Queue', 'Stack', 'Array', 'Linked List'],
        'correct': 'Stack',
        'explanation': 'A stack follows the LIFO principle - the last element added is the first one removed',
        'difficulty': 'easy',
      },
      {
        'question': 'What does the following code output? System.out.println(5 / 2);',
        'options': ['2.5', '2', '3', 'Error'],
        'correct': '2',
        'explanation': 'Integer division in Java truncates the decimal part, so 5/2 = 2',
        'difficulty': 'medium',
      },
    ],

    // Mathematics (General)
    'Mathematics': [
      {
        'question': 'What is the quadratic formula?',
        'options': [
          'x = (-b ± √(b² - 4ac)) / 2a',
          'x = (-b ± √(b² + 4ac)) / 2a',
          'x = (b ± √(b² - 4ac)) / 2a',
          'x = (-b ± √(b² - 4ac)) / a'
        ],
        'correct': 'x = (-b ± √(b² - 4ac)) / 2a',
        'explanation': 'The quadratic formula solves ax² + bx + c = 0',
        'difficulty': 'medium',
      },
      {
        'question': 'Solve for x: 2x + 5 = 13',
        'options': ['x = 3', 'x = 4', 'x = 5', 'x = 6'],
        'correct': 'x = 4',
        'explanation': 'Subtract 5 from both sides: 2x = 8, then divide by 2: x = 4',
        'difficulty': 'easy',
      },
    ],

    // Physics (General)
    'Physics': [
      {
        'question': 'What is Newton\'s second law of motion?',
        'options': ['F = ma', 'E = mc²', 'v = u + at', 'P = mv'],
        'correct': 'F = ma',
        'explanation': 'Newton\'s second law states that Force equals mass times acceleration',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the speed of light in vacuum?',
        'options': ['3 × 10⁸ m/s', '3 × 10⁶ m/s', '3 × 10¹⁰ m/s', '3 × 10⁴ m/s'],
        'correct': '3 × 10⁸ m/s',
        'explanation': 'The speed of light in vacuum is approximately 299,792,458 m/s or 3 × 10⁸ m/s',
        'difficulty': 'medium',
      },
    ],
  };

  /// Get questions for a specific subject
  static List<Question> getQuestionsForSubject(String subjectName, int subjectId) {
    final questions = <Question>[];
    
    // Try exact match first
    final subjectQuestions = questionsBySubject[subjectName];
    if (subjectQuestions != null) {
      for (final questionData in subjectQuestions) {
        questions.add(Question(
          subjectId: subjectId,
          subjectName: subjectName,
          questionText: questionData['question'],
          options: List<String>.from(questionData['options']),
          correctAnswer: questionData['correct'],
          explanation: questionData['explanation'],
          difficulty: questionData['difficulty'] ?? 'medium',
          category: subjectName,
          questionType: 'multiple',
          source: 'Subject-Specific Question Bank',
          isFromAI: false,
          createdAt: DateTime.now(),
        ));
      }
    }
    
    // If no exact match, try partial matches for broader subjects
    if (questions.isEmpty) {
      for (final entry in questionsBySubject.entries) {
        if (subjectName.toLowerCase().contains(entry.key.toLowerCase()) ||
            entry.key.toLowerCase().contains(subjectName.toLowerCase())) {
          for (final questionData in entry.value) {
            questions.add(Question(
              subjectId: subjectId,
              subjectName: subjectName,
              questionText: questionData['question'],
              options: List<String>.from(questionData['options']),
              correctAnswer: questionData['correct'],
              explanation: questionData['explanation'],
              difficulty: questionData['difficulty'] ?? 'medium',
              category: entry.key,
              questionType: 'multiple',
              source: 'Subject-Specific Question Bank',
              isFromAI: false,
              createdAt: DateTime.now(),
            ));
          }
          break; // Only use first match to avoid duplicates
        }
      }
    }
    
    return questions;
  }

  /// Get a random question for a specific subject
  static Question? getRandomQuestionForSubject(String subjectName, int subjectId) {
    final questions = getQuestionsForSubject(subjectName, subjectId);
    
    if (questions.isEmpty) {
      return null;
    }
    
    final random = DateTime.now().millisecondsSinceEpoch % questions.length;
    return questions[random];
  }

  /// Get question count for a subject
  static int getQuestionCountForSubject(String subjectName) {
    final subjectQuestions = questionsBySubject[subjectName];
    if (subjectQuestions != null) {
      return subjectQuestions.length;
    }
    
    // Check for partial matches
    for (final entry in questionsBySubject.entries) {
      if (subjectName.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(subjectName.toLowerCase())) {
        return entry.value.length;
      }
    }
    
    return 0;
  }

  /// Get all available subjects
  static List<String> getAllSubjects() {
    return questionsBySubject.keys.toList();
  }
}
