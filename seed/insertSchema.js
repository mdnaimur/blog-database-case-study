/*
 * Title: Database Seeding Script
 * Description: This script is used to seed the database with initial data
 * Author: Md Naimur Rahman
 * Date: 01/08/2026
 */



const client = require("./db");

const {faker} = require("@faker-js/faker");


//-------------
// USERS
//-------------

async function insertUsers(){
  
  for(let i = 1; i < 1000; i++){
    
    const role = i <= 2 ? "admin" : i <= 5 ? "author" : "reader";

    await client.query(
    `INSERT INTO users (username, email, password, role)
    VALUES ($1 , $2, $3, $4)`, 
    [
      faker.internet.username(),
      faker.internet.email(),
      "hashed_password ",
      role
    ]
    );

  }
}


//-------------
// AUTHORS
//-------------

async function insertAuthors(){
  const users = await client.query(`SELECT user_id FROM users`);

  for ( const user of users.rows){

    await client.query(
      `INSERT INTO authors
       (author_id, 
       bio, 
       first_name,
        last_name,
       profile_picture_url, 
       author_status)
      VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        user.user_id,
        faker.lorem.paragraph(),
        faker.person.firstName(),
        faker.person.lastName(),
        faker.image.avatar(),
        faker.helpers.arrayElement(['active', 'inactive'])
      ]
      
    )
  }
}

//-------------
// CATEGORIES
//-------------

async function insertCategories(){   

      const categories = [
      "Technology",
      "Programming",
      "Database",
      "Backend",
      "JavaScript",
    ];

    for (const category of categories) {
      await client.query(
        `INSERT INTO categories (category_name, description)
         VALUES ($1, $2)`,
        [
          category, 
          faker.lorem.sentence()]
      );
    } 


 }

 //-------------
// POSTS
//-------------

async function insertPosts() {
  const authors = await client.query(`SELECT author_id FROM authors`);

for (const author of authors.rows) {

  const randomAuthor = authors.rows[Math.floor(Math.random() * authors.rows.length)];

  await client.query(
    `INSERT INTO posts (author_id, title, content, post_status,published_at)
     VALUES ($1, $2, $3, $4, $5)`,
    [
      randomAuthor.author_id,
      faker.lorem.sentence(),
      faker.lorem.paragraphs(3),
      faker.helpers.arrayElement(['published', 'draft']),
      faker.date.recent()
    ]
  );  

}

 }


 //-------------
 // post_categories
 //-------------

async function insertPostCategories() {
  const posts = await client.query(`SELECT post_id FROM posts`);
  const categories = await client.query(`SELECT category_id FROM categories`);

  for (const post of posts.rows) {
    const randomCategory = categories.rows[Math.floor(Math.random() * categories.rows.length)];

    await client.query(
      `INSERT INTO post_categories (post_id, category_id)
       VALUES ($1, $2)`,
      [
        post.post_id,
        randomCategory.category_id
      ]
    );
  }
}


//-------------
// COMMENTS
//-------------

async function insertComments() {
  const posts = await client.query(`SELECT post_id FROM posts`);
  const users = await client.query(`SELECT user_id FROM users`);

  for (let i = 1; i <= 3000; i++) {
    const randomUser = users.rows[Math.floor(Math.random() * users.rows.length)];
    const randomPost = posts.rows[Math.floor(Math.random() * posts.rows.length)];

    await client.query(
      `INSERT INTO comments (
      content, 
      blog_post_id,
       user_id)
       VALUES ($1, $2, $3)`,
      [
        faker.lorem.sentences(2),
        randomPost.post_id,
        randomUser.user_id  
      ]
    );  
    
  }
}


//-------------
// vIEW COUNT
//-------------

async function insertViewCounts() {
  const posts = await client.query(`SELECT post_id FROM posts`);


  for (let post = 1; post <= 4500; post++) {


    const randomPost = posts.rows[Math.floor(Math.random() * posts.rows.length)];

    await client.query(
      `INSERT INTO view_counts (blog_post_id,  view_count)
       VALUES ($1, $2)`,
      [
        randomPost.post_id,
        Math.floor(Math.random() * 100)
      ]
    );
  }
}


//-------------
// view log
//-------------

async function insertViewLogs() {
  const posts = await client.query(`SELECT post_id FROM posts`);
  const users = await client.query(`SELECT user_id FROM users`);  


  for (let i = 1; i <= 5000; i++) {

    const randomUser = users.rows[Math.floor(Math.random() * users.rows.length)];
    const randomPost = posts.rows[Math.floor(Math.random() * posts.rows.length)];

    await client.query(
      `INSERT INTO view_logs (view_log_id, blog_post_id, user_id)
       VALUES ($1, $2, $3)`,
      [
        i,
       randomPost.post_id,
        randomUser.user_id
      ]
    );
  }


}

module.exports = {
  insertUsers,
  insertAuthors,
  insertCategories,
  insertPosts,
  insertPostCategories,
  insertComments,
  insertViewCounts,
  insertViewLogs
};