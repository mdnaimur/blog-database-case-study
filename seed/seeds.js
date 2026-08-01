/*
 * Title: Database Seeding Script
 * Description: 
 * Author: Md Naimur Rahman
 * Date: 01/08/2026
 */



require("dotenv").config();

const client = require("./db");

const { 
  insertUsers, 
  insertAuthors,
  insertPosts,
  insertComments ,
  insertCategories,
  insertPostCategories,
  insertViewCounts,
  insertViewLogs
  } = require("./insertSchema");



async function seedDatabase() {

  try{
    await client.connect();
    console.log('Connected to the database');

    await insertUsers();
    console.log('Users inserted successfully');
    await insertAuthors();
    console.log('Authors inserted successfully');
    await insertPosts();
    console.log('Posts inserted successfully');
    await insertComments();
    console.log('Comments inserted successfully');
    await insertCategories();
    console.log('Categories inserted successfully');
    await insertPostCategories();
    console.log('Post Categories inserted successfully');
    await insertViewCounts();
    console.log('View Counts inserted successfully');
    await insertViewLogs();
    console.log('View Logs inserted successfully');
  }
  catch(err){
    console.error('Error connecting to the database:', err);
    process.exit(1);
  }
}

seedDatabase().then(() => {
  console.log('Database seeding completed');
  client.end();
}).catch((err) => {
  console.error('Error seeding the database:', err);
  client.end();
}   )