import '../models/question.dart';

class QuestionBank {
  static const Map<String, List<Map<String, dynamic>>> questionsBySubject = {
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
      {
        'question': 'If f(x) = e^(2x), what is f\'(x)?',
        'options': ['e^(2x)', '2e^(2x)', 'e^x', '2e^x'],
        'correct': '2e^(2x)',
        'explanation': 'Using the chain rule: d/dx[e^(2x)] = e^(2x) · d/dx[2x] = e^(2x) · 2 = 2e^(2x)',
        'difficulty': 'medium',
      },
      {
        'question': 'What is the area under the curve y = x² from x = 0 to x = 2?',
        'options': ['8/3', '4', '8', '16/3'],
        'correct': '8/3',
        'explanation': '∫₀² x² dx = [x³/3]₀² = 8/3 - 0 = 8/3',
        'difficulty': 'medium',
      },
    ],

    'AP Calculus BC': [
      {
        'question': 'What is the Taylor series for e^x centered at x = 0?',
        'options': ['∑(x^n/n!)', '∑((-1)^n x^n/n!)', '∑(x^n)', '∑(n·x^n)'],
        'correct': '∑(x^n/n!)',
        'explanation': 'The Taylor series for e^x is ∑(n=0 to ∞) x^n/n! = 1 + x + x²/2! + x³/3! + ...',
        'difficulty': 'hard',
      },
      {
        'question': 'Find the radius of convergence for ∑(x^n/n)',
        'options': ['1', '2', '∞', '1/2'],
        'correct': '1',
        'explanation': 'Using the ratio test: lim|aₙ₊₁/aₙ| = lim|n/(n+1)| = 1, so R = 1',
        'difficulty': 'hard',
      },
      {
        'question': 'What is the arc length of y = x^(3/2) from x = 0 to x = 4?',
        'options': ['8', '56/27', '56/9', '28/9'],
        'correct': '56/9',
        'explanation': 'Arc length = ∫₀⁴ √(1 + (dy/dx)²) dx where dy/dx = (3/2)x^(1/2)',
        'difficulty': 'hard',
      },
    ],

    'AP Physics 1': [
      {
        'question': 'A ball is thrown horizontally from a height of 20 m. How long does it take to hit the ground?',
        'options': ['2.0 s', '2.02 s', '1.8 s', '2.5 s'],
        'correct': '2.02 s',
        'explanation': 'Using h = ½gt²: 20 = ½(9.8)t², solving gives t = √(40/9.8) ≈ 2.02 s',
        'difficulty': 'medium',
      },
      {
        'question': 'What is Newton\'s Second Law?',
        'options': ['F = ma', 'F = mv', 'F = ma²', 'F = m/a'],
        'correct': 'F = ma',
        'explanation': 'Newton\'s Second Law states that the net force equals mass times acceleration',
        'difficulty': 'easy',
      },
      {
        'question': 'A 5 kg object accelerates at 2 m/s². What is the net force?',
        'options': ['10 N', '7 N', '3 N', '2.5 N'],
        'correct': '10 N',
        'explanation': 'Using F = ma: F = 5 kg × 2 m/s² = 10 N',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the period of a simple pendulum with length 1 m?',
        'options': ['2.0 s', '1.0 s', 'π s', '2π s'],
        'correct': '2.0 s',
        'explanation': 'T = 2π√(L/g) = 2π√(1/9.8) ≈ 2.0 s',
        'difficulty': 'medium',
      },
      {
        'question': 'Which has more momentum: a 1000 kg car at 20 m/s or a 2000 kg truck at 10 m/s?',
        'options': ['Car', 'Truck', 'Same', 'Cannot determine'],
        'correct': 'Same',
        'explanation': 'Car: p = 1000 × 20 = 20,000 kg⋅m/s; Truck: p = 2000 × 10 = 20,000 kg⋅m/s',
        'difficulty': 'medium',
      },
    ],

    'AP Physics 2': [
      {
        'question': 'What is the electric field at a distance r from a point charge Q?',
        'options': ['kQ/r²', 'kQ/r', 'kQ²/r²', 'Q/4πε₀r²'],
        'correct': 'kQ/r²',
        'explanation': 'Coulomb\'s law for electric field: E = kQ/r² where k = 1/4πε₀',
        'difficulty': 'medium',
      },
      {
        'question': 'What happens to pressure when temperature increases at constant volume?',
        'options': ['Increases', 'Decreases', 'Stays same', 'Becomes zero'],
        'correct': 'Increases',
        'explanation': 'Gay-Lussac\'s Law: P/T = constant, so P ∝ T at constant volume',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the capacitance of a parallel plate capacitor?',
        'options': ['ε₀A/d', 'ε₀d/A', 'A/ε₀d', 'd/ε₀A'],
        'correct': 'ε₀A/d',
        'explanation': 'C = ε₀A/d where A is plate area and d is separation distance',
        'difficulty': 'medium',
      },
    ],

    'AP Chemistry': [
      {
        'question': 'What is the electron configuration of oxygen?',
        'options': ['1s² 2s² 2p⁴', '1s² 2s² 2p⁶', '1s² 2s² 2p²', '1s² 2p⁶'],
        'correct': '1s² 2s² 2p⁴',
        'explanation': 'Oxygen has 8 electrons: 2 in 1s, 2 in 2s, and 4 in 2p orbitals',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the pH of a 0.01 M HCl solution?',
        'options': ['2', '1', '12', '14'],
        'correct': '2',
        'explanation': 'HCl is a strong acid, so [H⁺] = 0.01 M. pH = -log(0.01) = 2',
        'difficulty': 'medium',
      },
      {
        'question': 'How many moles are in 22.4 L of gas at STP?',
        'options': ['1 mol', '2 mol', '0.5 mol', '22.4 mol'],
        'correct': '1 mol',
        'explanation': 'At STP, 1 mole of any gas occupies 22.4 L (molar volume)',
        'difficulty': 'easy',
      },
      {
        'question': 'What type of bond forms between Na and Cl?',
        'options': ['Ionic', 'Covalent', 'Metallic', 'Hydrogen'],
        'correct': 'Ionic',
        'explanation': 'Na loses an electron to Cl, forming Na⁺ and Cl⁻ ions held by electrostatic attraction',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the molecular geometry of CH₄?',
        'options': ['Tetrahedral', 'Linear', 'Bent', 'Trigonal planar'],
        'correct': 'Tetrahedral',
        'explanation': 'CH₄ has 4 bonding pairs around carbon with no lone pairs, giving tetrahedral geometry',
        'difficulty': 'medium',
      },
    ],

    'AP Biology': [
      {
        'question': 'What is the powerhouse of the cell?',
        'options': ['Mitochondria', 'Nucleus', 'Ribosome', 'Chloroplast'],
        'correct': 'Mitochondria',
        'explanation': 'Mitochondria produce ATP through cellular respiration, providing energy for cellular processes',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the complementary DNA strand to ATCG?',
        'options': ['TAGC', 'UAGC', 'CGAT', 'GCTA'],
        'correct': 'TAGC',
        'explanation': 'DNA base pairing: A pairs with T, T pairs with A, C pairs with G, G pairs with C',
        'difficulty': 'easy',
      },
      {
        'question': 'Where does photosynthesis occur in plant cells?',
        'options': ['Chloroplasts', 'Mitochondria', 'Nucleus', 'Vacuole'],
        'correct': 'Chloroplasts',
        'explanation': 'Chloroplasts contain chlorophyll and are the site of photosynthesis in plant cells',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the process by which cells divide to produce gametes?',
        'options': ['Meiosis', 'Mitosis', 'Binary fission', 'Budding'],
        'correct': 'Meiosis',
        'explanation': 'Meiosis produces haploid gametes (sex cells) from diploid parent cells',
        'difficulty': 'medium',
      },
      {
        'question': 'What is the role of tRNA in protein synthesis?',
        'options': ['Brings amino acids to ribosome', 'Carries genetic code', 'Forms ribosome structure', 'Catalyzes reactions'],
        'correct': 'Brings amino acids to ribosome',
        'explanation': 'tRNA molecules transport specific amino acids to the ribosome during translation',
        'difficulty': 'medium',
      },
    ],

    'AP Statistics': [
      {
        'question': 'What is the mean of the dataset: 2, 4, 6, 8, 10?',
        'options': ['6', '5', '7', '8'],
        'correct': '6',
        'explanation': 'Mean = (2 + 4 + 6 + 8 + 10) ÷ 5 = 30 ÷ 5 = 6',
        'difficulty': 'easy',
      },
      {
        'question': 'In a normal distribution, what percentage of data falls within one standard deviation?',
        'options': ['68%', '95%', '99.7%', '50%'],
        'correct': '68%',
        'explanation': 'The empirical rule: ~68% within 1σ, ~95% within 2σ, ~99.7% within 3σ',
        'difficulty': 'medium',
      },
      {
        'question': 'What is the probability of getting heads on a fair coin flip?',
        'options': ['0.5', '0.25', '1', '0'],
        'correct': '0.5',
        'explanation': 'A fair coin has equal probability for heads and tails: P(heads) = 1/2 = 0.5',
        'difficulty': 'easy',
      },
    ],

    'AP English Language and Composition': [
      {
        'question': 'What is ethos in rhetoric?',
        'options': ['Appeal to credibility', 'Appeal to emotion', 'Appeal to logic', 'Appeal to tradition'],
        'correct': 'Appeal to credibility',
        'explanation': 'Ethos establishes the speaker\'s credibility and trustworthiness',
        'difficulty': 'easy',
      },
      {
        'question': 'What is a thesis statement?',
        'options': ['Main argument of essay', 'Supporting evidence', 'Conclusion summary', 'Topic sentence'],
        'correct': 'Main argument of essay',
        'explanation': 'A thesis statement presents the central claim or argument that the essay will support',
        'difficulty': 'easy',
      },
    ],

    'AP United States History': [
      {
        'question': 'When was the Declaration of Independence signed?',
        'options': ['1776', '1775', '1777', '1783'],
        'correct': '1776',
        'explanation': 'The Declaration of Independence was adopted on July 4, 1776',
        'difficulty': 'easy',
      },
      {
        'question': 'What was the main cause of the Civil War?',
        'options': ['Slavery', 'Taxation', 'Trade disputes', 'Religious differences'],
        'correct': 'Slavery',
        'explanation': 'The primary cause was the disagreement over slavery and its expansion into new territories',
        'difficulty': 'medium',
      },
    ],

    'Mathematics': [
      {
        'question': 'Solve for x: 2x + 5 = 13',
        'options': ['x = 3', 'x = 4', 'x = 5', 'x = 6'],
        'correct': 'x = 4',
        'explanation': 'Subtract 5 from both sides: 2x = 8, then divide by 2: x = 4',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the slope of the line y = 3x + 2?',
        'options': ['2', '3', '5', '1'],
        'correct': '3',
        'explanation': 'In the form y = mx + b, the coefficient of x (m) is the slope',
        'difficulty': 'easy',
      },
      {
        'question': 'Factor: x² - 9',
        'options': ['(x-3)(x-3)', '(x+3)(x-3)', '(x+9)(x-1)', 'Cannot be factored'],
        'correct': '(x+3)(x-3)',
        'explanation': 'This is a difference of squares: a² - b² = (a+b)(a-b)',
        'difficulty': 'medium',
      },
    ],

    'Physics': [
      {
        'question': 'An object at rest will stay at rest unless acted upon by what?',
        'options': ['Gravity', 'An unbalanced force', 'Friction', 'Momentum'],
        'correct': 'An unbalanced force',
        'explanation': 'This is Newton\'s First Law of Motion (Law of Inertia)',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the formula for kinetic energy?',
        'options': ['KE = mv', 'KE = ½mv²', 'KE = mgh', 'KE = Fd'],
        'correct': 'KE = ½mv²',
        'explanation': 'Kinetic energy equals one-half mass times velocity squared',
        'difficulty': 'medium',
      },
    ],

    'Chemistry': [
      {
        'question': 'How many electrons can the first energy level hold?',
        'options': ['2', '8', '18', '32'],
        'correct': '2',
        'explanation': 'The first energy level (n=1) can hold a maximum of 2 electrons',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the chemical formula for water?',
        'options': ['H2O', 'CO2', 'NaCl', 'O2'],
        'correct': 'H2O',
        'explanation': 'Water is composed of two hydrogen atoms and one oxygen atom',
        'difficulty': 'easy',
      },
    ],
  };

  static List<Question> getQuestionsForSubject(String subjectName, int subjectId) {
    final questions = questionsBySubject[subjectName] ?? questionsBySubject['Mathematics'] ?? [];
    
    return questions.map((q) => Question(
      subjectId: subjectId,
      questionText: q['question'] as String,
      options: List<String>.from(q['options'] as List),
      correctAnswer: q['correct'] as String,
      explanation: q['explanation'] as String,
      difficulty: q['difficulty'] as String,
      createdAt: DateTime.now(),
      isFromAI: false,
      source: 'Curriculum Question Bank',
    )).toList();
  }

  static Question getRandomQuestionForSubject(String subjectName, int subjectId) {
    final questions = getQuestionsForSubject(subjectName, subjectId);
    if (questions.isEmpty) {
      // Fallback to basic math question
      return Question(
        subjectId: subjectId,
        questionText: 'What is 2 + 2?',
        options: ['3', '4', '5', '6'],
        correctAnswer: '4',
        explanation: 'Basic addition: 2 + 2 = 4',
        difficulty: 'easy',
        createdAt: DateTime.now(),
        isFromAI: false,
        source: 'Basic Question Bank',
      );
    }
    
    final random = DateTime.now().millisecondsSinceEpoch % questions.length;
    return questions[random];
  }

  static int getQuestionCountForSubject(String subjectName) {
    return questionsBySubject[subjectName]?.length ?? 0;
  }
}
