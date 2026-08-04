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
  
  for(let i = 1; i <= 10000; i++){
    
    const role = i <= 2 ? "admin" : i <= 5 ? "author" : "reader";

    await client.query(
    `INSERT INTO users (username, email, password, role)
    VALUES ($1 , $2, $3, $4)`, 
    [
      `${faker.internet.username()}_${i}`,
      `user${i}@example.com`,
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

  // const randomAuthor = authors.rows[Math.floor(Math.random() * authors.rows.length)];

  await client.query(
    `INSERT INTO blog_posts (author_id, title, content, post_status,published_at)
     VALUES ($1, $2, $3, $4, $5)`,
    [
      author.author_id,
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
  const posts = await client.query(`SELECT blog_post_id FROM blog_posts`);
  const categories = await client.query(`SELECT cat_id FROM categories`);

  for (const post of posts.rows) {
    const randomCategory = categories.rows[Math.floor(Math.random() * categories.rows.length)];

    await client.query(
      `INSERT INTO post_categories (blog_post_id, cat_id)
       VALUES ($1, $2)`,
      [
        post.blog_post_id,
        randomCategory.cat_id
      ]
    );
  }
}


//-------------
// COMMENTS
//-------------

async function insertComments() {
  const posts = await client.query(`SELECT blog_post_id FROM blog_posts`);
  const users = await client.query(`SELECT user_id FROM users`);

  for (let i = 1; i <= 30000; i++) {
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
        randomPost.blog_post_id,
        randomUser.user_id  
      ]
    );  
    
  }
}


//-------------
// vIEW COUNT
//-------------

async function insertViewCounts() {
  const posts = await client.query(`SELECT blog_post_id FROM blog_posts`);


  for (const post of posts.rows) {


    // const randomPost = posts.rows[Math.floor(Math.random() * posts.rows.length)];

    await client.query(
      `INSERT INTO post_view_count (blog_post_id,  view_count)
       VALUES ($1, $2)`,
      [
        post.blog_post_id,
        faker.number.int({min:0,max:1000})
      ]
    );
  }
}


//-------------
// view log
//-------------

async function insertViewLogs() {
  const posts = await client.query(`SELECT blog_post_id FROM blog_posts`);
  const users = await client.query(`SELECT user_id FROM users`);  


  for (let i = 1; i <= 50000; i++) {

    const randomUser = users.rows[Math.floor(Math.random() * users.rows.length)];
    const randomPost = posts.rows[Math.floor(Math.random() * posts.rows.length)];

    await client.query(
      `INSERT INTO post_view_logs ( blog_post_id, user_id)
       VALUES ($1, $2)`,
      [
        randomPost.blog_post_id,
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