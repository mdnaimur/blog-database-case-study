require("dotenv").config();

const { Pool } = require("pg");

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: false
});


// async function connectDB() {
//   await pool.connect();
//   console.log('Connected to the database');
// }

// connectDB().catch((err) => {
//   console.error('Error connecting to the database:', err);
//   process.exit(1);
// });


module.exports = pool;