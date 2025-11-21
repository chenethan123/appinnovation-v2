-- ============================================
-- COURSE CATALOG - SEED DATA
-- ============================================
-- This pre-populates the course_catalog table with 127 courses
-- Run this AFTER running supabase_course_catalog_schema.sql
-- ============================================

-- Disable triggers temporarily for bulk insert
ALTER TABLE course_catalog DISABLE TRIGGER ALL;

-- Insert all courses
INSERT INTO course_catalog (course_id, subject_name, category, description, display_order) VALUES
  ('AP-CALC-AB', 'AP Calculus AB', 'STEM', 'Advanced Placement Calculus - derivatives and integrals', 1),
  ('AP-CALC-BC', 'AP Calculus BC', 'STEM', 'Advanced Placement Calculus - includes series and parametric equations', 2),
  ('AP-STAT', 'AP Statistics', 'STEM', 'Advanced Placement Statistics - data analysis and inference', 3),
  ('AP-CS-A', 'AP Computer Science A', 'STEM', 'Advanced Placement Computer Science - Java programming', 4),
  ('AP-CS-P', 'AP Computer Science Principles', 'STEM', 'Advanced Placement CS Principles - computational thinking', 5),
  ('AP-PHYS-1', 'AP Physics 1', 'STEM', 'Advanced Placement Physics - mechanics', 6),
  ('AP-PHYS-2', 'AP Physics 2', 'STEM', 'Advanced Placement Physics - electricity, magnetism, fluids', 7),
  ('AP-PHYS-C-MECH', 'AP Physics C: Mechanics', 'STEM', 'Advanced Placement Physics - calculus-based mechanics', 8),
  ('AP-PHYS-C-EM', 'AP Physics C: Electricity and Magnetism', 'STEM', 'Advanced Placement Physics - calculus-based E&M', 9),
  ('AP-CHEM', 'AP Chemistry', 'STEM', 'Advanced Placement Chemistry - atomic structure, bonding, reactions', 10),
  ('AP-BIO', 'AP Biology', 'STEM', 'Advanced Placement Biology - cells, genetics, evolution, ecology', 11),
  ('AP-ENVIRO', 'AP Environmental Science', 'STEM', 'Advanced Placement Environmental Science - ecosystems and sustainability', 12),
  ('AP-ENG-LANG', 'AP English Language and Composition', 'Humanities', 'Advanced Placement English - rhetoric and composition', 13),
  ('AP-ENG-LIT', 'AP English Literature and Composition', 'Humanities', 'Advanced Placement English - literary analysis', 14),
  ('AP-USHIST', 'AP United States History', 'Humanities', 'Advanced Placement US History - colonial period to present', 15),
  ('AP-WHIST', 'AP World History: Modern', 'Humanities', 'Advanced Placement World History - 1200 CE to present', 16),
  ('AP-EUROHIST', 'AP European History', 'Humanities', 'Advanced Placement European History - Renaissance to present', 17),
  ('AP-ARTHIST', 'AP Art History', 'Humanities', 'Advanced Placement Art History - global art traditions', 18),
  ('AP-MUSIC', 'AP Music Theory', 'Humanities', 'Advanced Placement Music Theory - composition and analysis', 19),
  ('AP-PSYCH', 'AP Psychology', 'Social Science', 'Advanced Placement Psychology - behavior and mental processes', 20),
  ('AP-MICRO', 'AP Microeconomics', 'Social Science', 'Advanced Placement Microeconomics - supply, demand, markets', 21),
  ('AP-MACRO', 'AP Macroeconomics', 'Social Science', 'Advanced Placement Macroeconomics - national economy and policy', 22),
  ('AP-USGOV', 'AP United States Government and Politics', 'Social Science', 'Advanced Placement US Government - political institutions', 23),
  ('AP-COMPGOV', 'AP Comparative Government and Politics', 'Social Science', 'Advanced Placement Comparative Government - global political systems', 24),
  ('AP-HUMGEO', 'AP Human Geography', 'Social Science', 'Advanced Placement Human Geography - spatial patterns and processes', 25),
  ('AP-SPAN-LANG', 'AP Spanish Language and Culture', 'Languages', 'Advanced Placement Spanish - language proficiency and cultural understanding', 26),
  ('AP-SPAN-LIT', 'AP Spanish Literature and Culture', 'Languages', 'Advanced Placement Spanish Literature - literary analysis in Spanish', 27),
  ('AP-FREN', 'AP French Language and Culture', 'Languages', 'Advanced Placement French - language proficiency and cultural understanding', 28),
  ('AP-GERM', 'AP German Language and Culture', 'Languages', 'Advanced Placement German - language proficiency and cultural understanding', 29),
  ('AP-CHIN', 'AP Chinese Language and Culture', 'Languages', 'Advanced Placement Chinese - Mandarin proficiency and cultural understanding', 30),
  ('AP-ITAL', 'AP Italian Language and Culture', 'Languages', 'Advanced Placement Italian - language proficiency and cultural understanding', 31),
  ('AP-JAPN', 'AP Japanese Language and Culture', 'Languages', 'Advanced Placement Japanese - language proficiency and cultural understanding', 32),
  ('AP-LATIN', 'AP Latin', 'Languages', 'Advanced Placement Latin - classical Latin language and Roman culture', 33),
  ('MATH 101', 'College Algebra', 'STEM', 'Introduction to algebraic concepts and problem-solving', 34),
  ('MATH 110', 'Precalculus', 'STEM', 'Preparation for calculus including functions, trigonometry', 35),
  ('MATH 120', 'Calculus I', 'STEM', 'Limits, derivatives, and applications', 36),
  ('MATH 121', 'Calculus II', 'STEM', 'Integration techniques and applications', 37),
  ('MATH 220', 'Calculus III', 'STEM', 'Multivariable calculus and vector analysis', 38),
  ('MATH 230', 'Linear Algebra', 'STEM', 'Matrices, vector spaces, and linear transformations', 39),
  ('MATH 240', 'Differential Equations', 'STEM', 'Ordinary differential equations and applications', 40),
  ('MATH 310', 'Discrete Mathematics', 'STEM', 'Logic, set theory, combinatorics, and graph theory', 41),
  ('STAT 101', 'Introduction to Statistics', 'STEM', 'Descriptive statistics, probability, and inference', 42),
  ('STAT 200', 'Probability Theory', 'STEM', 'Mathematical foundations of probability', 43),
  ('CS 101', 'Introduction to Computer Science', 'STEM', 'Programming fundamentals and computational thinking', 44),
  ('CS 102', 'Data Structures', 'STEM', 'Arrays, lists, trees, graphs, and algorithms', 45),
  ('CS 201', 'Algorithms', 'STEM', 'Algorithm design and analysis', 46),
  ('CS 250', 'Computer Architecture', 'STEM', 'Hardware organization and assembly language', 47),
  ('CS 301', 'Operating Systems', 'STEM', 'Process management, memory, and file systems', 48),
  ('CS 310', 'Database Systems', 'STEM', 'Relational databases, SQL, and database design', 49),
  ('CS 340', 'Software Engineering', 'STEM', 'Software development lifecycle and methodologies', 50),
  ('CS 350', 'Artificial Intelligence', 'STEM', 'AI techniques including search, learning, and reasoning', 51),
  ('PHYS 101', 'Physics I - Mechanics', 'STEM', 'Kinematics, dynamics, energy, and momentum', 52),
  ('PHYS 102', 'Physics II - Electricity & Magnetism', 'STEM', 'Electric fields, circuits, and magnetic phenomena', 53),
  ('PHYS 201', 'Modern Physics', 'STEM', 'Quantum mechanics and relativity', 54),
  ('CHEM 101', 'General Chemistry I', 'STEM', 'Atomic structure, bonding, and stoichiometry', 55),
  ('CHEM 102', 'General Chemistry II', 'STEM', 'Thermodynamics, kinetics, and equilibrium', 56),
  ('CHEM 201', 'Organic Chemistry I', 'STEM', 'Structure and reactions of organic compounds', 57),
  ('CHEM 202', 'Organic Chemistry II', 'STEM', 'Advanced organic synthesis and mechanisms', 58),
  ('BIO 101', 'General Biology I', 'STEM', 'Cell biology, genetics, and molecular biology', 59),
  ('BIO 102', 'General Biology II', 'STEM', 'Evolution, ecology, and organismal biology', 60),
  ('BIO 201', 'Genetics', 'STEM', 'Principles of heredity and gene expression', 61),
  ('BIO 210', 'Microbiology', 'STEM', 'Bacteria, viruses, and microorganisms', 62),
  ('BIO 250', 'Anatomy & Physiology I', 'STEM', 'Human body structure and function', 63),
  ('ENG 101', 'English Composition I', 'Humanities', 'Academic writing and critical thinking', 64),
  ('ENG 102', 'English Composition II', 'Humanities', 'Research writing and argumentation', 65),
  ('ENG 201', 'British Literature', 'Humanities', 'Survey of British literary works', 66),
  ('ENG 202', 'American Literature', 'Humanities', 'Survey of American literary works', 67),
  ('ENG 250', 'Shakespeare', 'Humanities', 'Study of Shakespeare''s plays and sonnets', 68),
  ('HIST 101', 'World History I', 'Humanities', 'Ancient civilizations to 1500', 69),
  ('HIST 102', 'World History II', 'Humanities', '1500 to present', 70),
  ('HIST 201', 'American History I', 'Humanities', 'Colonial period to Civil War', 71),
  ('HIST 202', 'American History II', 'Humanities', 'Reconstruction to present', 72),
  ('PHIL 101', 'Introduction to Philosophy', 'Humanities', 'Major philosophical questions and thinkers', 73),
  ('PHIL 201', 'Ethics', 'Humanities', 'Moral philosophy and ethical theories', 74),
  ('PHIL 210', 'Logic', 'Humanities', 'Formal and informal reasoning', 75),
  ('PSYC 101', 'Introduction to Psychology', 'Social Science', 'Fundamentals of human behavior and mental processes', 76),
  ('PSYC 201', 'Developmental Psychology', 'Social Science', 'Human development across the lifespan', 77),
  ('PSYC 210', 'Abnormal Psychology', 'Social Science', 'Mental disorders and psychopathology', 78),
  ('PSYC 220', 'Social Psychology', 'Social Science', 'Social influence and group behavior', 79),
  ('ECON 101', 'Microeconomics', 'Social Science', 'Supply, demand, and market structures', 80),
  ('ECON 102', 'Macroeconomics', 'Social Science', 'National income, inflation, and fiscal policy', 81),
  ('ECON 201', 'Intermediate Microeconomics', 'Social Science', 'Advanced consumer and producer theory', 82),
  ('SOCI 101', 'Introduction to Sociology', 'Social Science', 'Social structures and institutions', 83),
  ('SOCI 201', 'Social Problems', 'Social Science', 'Contemporary social issues', 84),
  ('POLI 101', 'American Government', 'Social Science', 'U.S. political system and institutions', 85),
  ('POLI 201', 'Comparative Politics', 'Social Science', 'Political systems around the world', 86),
  ('ANTH 101', 'Cultural Anthropology', 'Social Science', 'Human cultures and societies', 87),
  ('COMM 101', 'Public Speaking', 'Humanities', 'Oral communication and presentation skills', 88),
  ('ART 101', 'Art History I', 'Humanities', 'Ancient to medieval art', 89),
  ('ART 102', 'Art History II', 'Humanities', 'Renaissance to contemporary art', 90),
  ('MUS 101', 'Music Appreciation', 'Humanities', 'Introduction to Western music', 91),
  ('SPAN 101', 'Elementary Spanish I', 'Languages', 'Basic Spanish language skills', 92),
  ('SPAN 102', 'Elementary Spanish II', 'Languages', 'Intermediate Spanish language skills', 93),
  ('FREN 101', 'Elementary French I', 'Languages', 'Basic French language skills', 94),
  ('GERM 101', 'Elementary German I', 'Languages', 'Basic German language skills', 95),
  ('CHIN 101', 'Elementary Chinese I', 'Languages', 'Basic Mandarin Chinese skills', 96),
  ('BUS 101', 'Introduction to Business', 'Business', 'Overview of business principles', 97),
  ('ACCT 101', 'Financial Accounting', 'Business', 'Accounting principles and financial statements', 98),
  ('MGMT 201', 'Principles of Management', 'Business', 'Management theories and practices', 99),
  ('MKTG 201', 'Principles of Marketing', 'Business', 'Marketing strategies and consumer behavior', 100),
  ('FIN 301', 'Corporate Finance', 'Business', 'Financial management and investment decisions', 101),
  ('ENG 210', 'Creative Writing', 'Humanities', 'Fiction, poetry, and creative nonfiction writing', 102),
  ('PHYS 220', 'Thermodynamics', 'STEM', 'Heat, energy, and entropy in physical systems', 103),
  ('CHEM 210', 'Analytical Chemistry', 'STEM', 'Quantitative analysis and laboratory techniques', 104),
  ('BIO 220', 'Biochemistry', 'STEM', 'Chemical processes within living organisms', 105),
  ('MATH 330', 'Abstract Algebra', 'STEM', 'Groups, rings, and fields', 106),
  ('MATH 340', 'Real Analysis', 'STEM', 'Rigorous foundations of calculus', 107),
  ('CS 320', 'Computer Networks', 'STEM', 'Network protocols, TCP/IP, and internet architecture', 108),
  ('CS 330', 'Machine Learning', 'STEM', 'Supervised and unsupervised learning algorithms', 109),
  ('CS 360', 'Computer Graphics', 'STEM', '3D rendering, animation, and visual computing', 110),
  ('ECON 210', 'Econometrics', 'Social Science', 'Statistical methods in economics', 111),
  ('PSYC 230', 'Cognitive Psychology', 'Social Science', 'Mental processes, memory, and perception', 112),
  ('PSYC 240', 'Behavioral Neuroscience', 'Social Science', 'Brain basis of behavior and cognition', 113),
  ('HIST 210', 'European History', 'Humanities', 'Major events in European civilization', 114),
  ('HIST 220', 'Asian History', 'Humanities', 'History of East and South Asia', 115),
  ('PHIL 220', 'Political Philosophy', 'Humanities', 'Justice, rights, and political theory', 116),
  ('PHIL 230', 'Philosophy of Mind', 'Humanities', 'Consciousness, perception, and mental states', 117),
  ('SPAN 201', 'Intermediate Spanish I', 'Languages', 'Advanced Spanish grammar and conversation', 118),
  ('SPAN 202', 'Intermediate Spanish II', 'Languages', 'Spanish literature and composition', 119),
  ('FREN 102', 'Elementary French II', 'Languages', 'Continuation of basic French', 120),
  ('JAPN 101', 'Elementary Japanese I', 'Languages', 'Basic Japanese language and writing systems', 121),
  ('BUS 201', 'Business Law', 'Business', 'Legal principles in business transactions', 122),
  ('BUS 210', 'Entrepreneurship', 'Business', 'Starting and managing new ventures', 123),
  ('ACCT 201', 'Managerial Accounting', 'Business', 'Cost analysis and management decisions', 124),
  ('ENGR 101', 'Introduction to Engineering', 'STEM', 'Engineering design and problem solving', 125),
  ('ENGR 201', 'Electrical Engineering', 'STEM', 'Circuit analysis and electrical systems', 126),
  ('ENGR 210', 'Mechanical Engineering', 'STEM', 'Mechanics, thermodynamics, and design', 127);

-- Re-enable triggers
ALTER TABLE course_catalog ENABLE TRIGGER ALL;

-- ============================================
-- VERIFICATION
-- ============================================

-- Count total courses (should be 127)
SELECT COUNT(*) as total_courses FROM course_catalog;

-- Count courses by category
SELECT 
  category,
  COUNT(*) as count
FROM course_catalog
GROUP BY category
ORDER BY category;

-- Show sample courses
SELECT 
  course_id,
  subject_name,
  category
FROM course_catalog
ORDER BY display_order
LIMIT 10;

-- Verify AP courses (should be 33)
SELECT COUNT(*) as ap_courses 
FROM course_catalog 
WHERE course_id LIKE 'AP-%';

-- Verify college courses (should be 94)
SELECT COUNT(*) as college_courses 
FROM course_catalog 
WHERE course_id NOT LIKE 'AP-%';

-- ✅ SEED DATA COMPLETE
-- Total courses inserted: 127 (33 AP + 94 college)
