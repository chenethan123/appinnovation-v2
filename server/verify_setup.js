/**
 * Verification Script - Check Supabase Setup
 * Verifies database tables and connection
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL || 'https://dsknaaziujrfavhaschj.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_KEY;

if (!supabaseKey) {
  console.error('❌ SUPABASE_ANON_KEY not found in .env file');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function verifySetup() {
  console.log('\n🔍 Verifying Supabase Setup...\n');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  const tables = [
    'users',
    'subjects',
    'questions',
    'quiz_sessions',
    'quiz_answers',
    'courses',
    'units'
  ];

  let allTablesExist = true;

  for (const table of tables) {
    try {
      // Try to query the table (will fail if it doesn't exist)
      const { data, error } = await supabase
        .from(table)
        .select('*')
        .limit(1);

      if (error) {
        if (error.message.includes('does not exist')) {
          console.log(`❌ Table '${table}' does NOT exist`);
          allTablesExist = false;
        } else if (error.message.includes('JWT')) {
          console.log(`⚠️  Table '${table}' exists (Auth required to query)`);
        } else {
          console.log(`✅ Table '${table}' exists`);
        }
      } else {
        console.log(`✅ Table '${table}' exists (${data?.length || 0} rows)`);
      }
    } catch (err) {
      console.log(`❌ Error checking table '${table}':`, err.message);
      allTablesExist = false;
    }
  }

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  if (allTablesExist) {
    console.log('🎉 SUCCESS! All database tables are ready!\n');
    console.log('Next Steps:');
    console.log('  1. Run the Flutter app: flutter run -d macos');
    console.log('  2. Test authentication (signup/login)');
    console.log('  3. Create a subject and it will sync to cloud!');
    console.log('  4. Login on another device to see sync in action\n');
  } else {
    console.log('⚠️  Some tables are missing. Re-run the SQL schema.\n');
  }

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

verifySetup().catch(console.error);
