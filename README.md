# Java Migrations Workshop

## Instructions

1. Fork this repository
2. Clone your fork to your machine
3. Open the project in IntelliJ (although we aren't doing any Java in this activity it does allow you to edit SQL).

### Learning Objectives

---

- Understand that database migrations are a way to control incremental changes to a database schema
- Understand that database migrations offer protection against destructive operations
- Understand that you can version control them as well as keep a log of the migrations so that it is possible to see a complete history of all of the various versions of your database
- Understand that it is also possible to integrate database migrations directly into your Java code so that it runs from there rather than as a separate  application


## Main

---

We will work on this using a tool called Flyway that can be run from the command line and talks to the database to create and update its structure.


### Installation

---

Go to [https://documentation.red-gate.com/fd/command-line-184127404.html](https://documentation.red-gate.com/fd/command-line-184127404.html) find the Community Edition download for your Operating System and download it.

Unzip the download into a folder where you want it to be installed/remain for the time you will be using it (you probably want to move it out of the Downloads folder, but where you put it is up to you).

In order to make the flyway application available to you from the command line you will probably need to add it to the PATH in some way (this depends on your Operating System). Once you have done that you will normally need to restart the Terminal that you are using for the change to be picked up.

Once you’ve done that, type **flyway** at the command prompt and press enter. If it has been picked up then it should show all of the available options for when flyway is run.

Running **flyway —version** should show the version of flyway you have just installed.

![version.png](assets/version.png)

### Connecting to the Database

---

In the previous session, you created a database and tables on Neon which you used Beeline Studio to connect to (using the connection details from Neon).

Flyway has various places it looks for a config file, which will hold the details of the database connection (in this order):

- `<install-dir>/conf/flyway.conf`
- `<user-home>/flyway.conf`
- `<current-dir>/flyway.conf`

If you put `flyway.toml` into your current directory it is very, very, very important that you **DO NOT** commit this to GitHub, as anyone with access to your repo could then use the credentials to access your Database. There are bots constantly scanning GitHub to steal these sorts of information in order to use them for potentially nefarious purposes.

You can use **.gitignore** to exclude this file from Git.

For now, you can use the one in your installation directory/conf and then change it if you need to connect to a different Database (that way it is outside of the Git repository directory).

Go to the **conf** directory which is inside **flyway**'s installation directory. Copy the `flyway.toml.example` file and paste a new copy with the updated name of just `flyway.toml`. Open the new file and you should see that some of it is commented out and some has default values.

```toml
# More information on the parameters can be found here: https://documentation.red-gate.com/flyway/flyway-cli-and-api/configuration/parameters

[environments.sample]
url = "jdbc:h2:mem:db"
user = "sample user"
password = "sample password"
# jarDirs = ["path/to/java/migrations"]
# driver =
# schemas =
# connectRetries =
# connectRetriesInterval =
# initSql =
# jdbcProperties =
# resolvers =

[flyway]
# environment = "sample" # It is recommended to configure environment as a commandline argument. This allows using different environments depending on the caller.
# locations = ["filesystem:path/to/sql/files"]

# [environments.build]
# url = "jdbc:sqlite::memory:"
# user = "buildUser"
# password = "buildPassword"

# [flyway.check]
# buildEnvironment = "build"
```

We need to make changes to the top part where it details, the connection details and then uncomment the part where the connection details are referenced.

Scroll down to the line that reads **flyway.locations=filesystem:sql*** and remove the part after the = sign. Change it so that it reads **flyway.locations=db/migrations** to make flyway read the current directory (where it is being run from) looking for a directory called **db** containing another one called **migrations** which will contain our database migration files.

Uncomment the line that starts with: **flyway.url** by removing the **#**.

Then after the **=** sign add the following:

`
jdbc:postgresql://<URL of the database>:5432/<Username/Database name>
`

Replace `<URL of the database>` with the **Hostname** details from ElephantSQL

Replace `<Username/Database name>` with the one shown in ElephantSQL.

![postgres-connection.png](assets/postgres-connection.png)

Uncomment the line that starts **flyway.user** and add the Username/Database name after it.

Uncomment the line that starts **flyway.password** and add the Password after it.

Make sure to save the **flyway.conf** file.

You can test your connection by typing:

**flyway migrate**

at the command line and hitting enter. If all is well you should see something that looks like:

![first-migrate.png](assets/first-migrate.png)

### Using Flyway to Create and Update a Database

---

Think about the Book database you started with yesterday.

First of all use TablePlus to go into the ElephantSQL database that was created yesterday and remove all of the tables using **drop table <name-of-table>** replacing <name-of-table> with the names of each table to remove.

Next we are going to create a Books database if we had it as a monolithic table it would look something like:

Books

**id**, title, author, publisher, year, genre, score, author_email, publisher_location

We’re going to use Flyway to create this table in our database.

The query we would use to do this looks like this:

```sql
CREATE TABLE IF NOT EXISTS Books(
	id serial primary key,
	title varchar(255) not null,
	author varchar(255),
	publisher varchar(255),
	year int,
	genre varchar(255),
	score int,
	author_email varchar(255),
	publisher_location varchar(255)
)
```

Rather than run it in TablePlus we are going to use flyway to iterate through creating and then changing (ie Migrating) the database until we get to a final version that matches what we want.

In the **db/migrations** folder in the repo create a new file called **V1_0_0__initial_table_creation.sql** and paste the above code to create the SQL table in it.

The name of the file is very important, it starts with a capital V, which can be changed somewhere in the config file, it is then followed by 1_0_0 which corresponds to the version of the database, subsequent files will need to follow on from this number, this is followed by a double underscore and then a description for what the file does (this bit is for you rather than the computer).

To run the file make sure you are in the top-level directory of the project in your terminal and type **flyway migrate** followed by enter. You should see something like this:

![table_creation.png](assets/table_creation.png)

In TablePlus look at the tables in the database, there should be a **Books** one which matches the one defined in our file.

Next, we want to modify the table we just created, we’re going to remove the author and author email columns from the Books table and replace them with a Foreign Key that points to the author in the new Authors table which we’re also going to be creating. We can put all of these changes into a single file, or we can put them into separate ones which are executed in order according to the numbering system which we use.

Add a file called **V2_0_0__create_authors_table.sql** and add a create table statement to it as follows.

```sql
 CREATE TABLE IF NOT EXISTS Authors (
    id serial PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255)
)
```

Which will create the new table. Then add another file called **V2_1_0__remove_author_details_from_books.sql** with the following SQL inside it.

```sql
ALTER TABLE Books
DROP COLUMN author,
DROP COLUMN author_email;
```

If there is any data in the Books table this will destroy the contents of these columns. In general, you will be working on a Development database with dummy data and this won’t matter as you would then recreate the data.

[**NOTE:** If you need to preserve the data and then write it to the new table preserving the relationships then you would need to create the new column (see next file), step through the records, capture the data, add it to the new table, get the new id, add it back into the Books table in the new column so that the existing author details now match the ID from the Authors table, and then remove the two columns. This can all be done in SQL, but for a production database with millions of lines of data it can be extremely non-trivial to do.]

Add yet another file called **V2_2_0__add_foreign_key_for_authors_to_books.sql** with the following SQL.

```sql
ALTER TABLE Books
ADD COLUMN author_id int;

ALTER TABLE Books
ADD CONSTRAINT fk_author_id FOREIGN KEY (author_id) REFERENCES Authors (id);
```

When adding the new column we need to make sure to specify what data type it has (the int in this case) as well as the name.

Foreign key constraints need to have a name and then we specify that the **author_id** column in Books is a reference to the **id** column (in brackets) of the **Authors** table.

To update the existing database with all of these changes we can just run **flyway migrate** again and it will look to see what the current version of the database is at and then apply the subsequent changes.

![multiple-migrates.png](assets/multiple-migrates.png)

If you want to see the current details of where the database migrations are up to we can do **flyway info** to get some details back.

![flyway-info.png](assets/flyway-info.png)

In the table you can see the 4 versioned files that have been added and the time stamps for when they were run.

If we want to remove all of the tables from the database because we made a mistake or want to start with a blank slate we can run: **flyway -cleanDisabled=false clean** which will remove all of the tables etc created by the migrations. We have to specify **-cleanDisabled=false** as this option is set to true by default. We could also find this option in the config file and set it to true there so that we don’t have to add this every time.

If we had a paid for version of **flyway** then at some tiers there is an extra command **flyway undo** which will remove the last migration that was applied which could be useful if we want to remove the final step. This is not available in the free version we are using. You can achieve the same effect by cleaning all of the migrations and then using target to only run them up to a certain point. So to get to the stage where the final migration has not been applied we would need to remove everything and then only apply the migrations up to a certain point we could do

**flyway -cleanDisabled=false clean**

**flyway -target=2.1 migrate**

This would clear everything out and then apply the migrations up to and including the **V2_1_0…** file but not including the **V2_2_0…** one.

![flyway-undoing.png](assets/flyway-undoing.png)

Looking at the output from **flyway info** you can see that it sees the final migration but doesn’t apply it.

Rerun **flyway migrate** and it will apply the final one.

Next, we’re going to do something similar to remove the publisher and publisher_location columns from the **Books** table, make a new table called **Publishers** with those columns and an id column in it and update **Books** to have a Foreign Key called publisher_id (in other words the same steps we did with the author).

Try and work through these steps to create files with Version numbers V3_0_0…, V3_1_0… and V3_2_0… the descriptions in the name are for your information about what the files do. Then look below to see the results.

### Example Solutions

**V3_0_0__create_publishers_table.sql**

```sql
CREATE TABLE IF NOT EXISTS Publishers (
    id serial PRIMARY KEY,
    name VARCHAR(255),
    location VARCHAR(255)
)
```

**V3_1_0__remove_publisher_details_from_books.sql**

```sql
ALTER TABLE Books
DROP COLUMN publisher,
DROP COLUMN publisher_location;
```

**V3_2_0__add_foriegn_key_for_publishers_to_books.sql**

```sql
ALTER TABLE Books
ADD COLUMN publisher_id int;

ALTER TABLE Books
ADD CONSTRAINT fk_publisher_id FOREIGN KEY (publisher_id) REFERENCES Publishers (id);
```
## Activity

Either change the location of the db migrations location in the config file, or move the existing migrations out of the **db/migrations** folder before starting this activity, and place the files to perform this migration in there.

Imagine you have a similar data structure for bands and their albums. Start by creating an Albums table which has the following columns (come up with your own logical names and data types for them):

- id
- name
- year of release
- highest chart position
- artist/band name
- number of members in the act
- artist/band year founded
- record company name
- record company location
- record company year founded

Create an initial migration file that will create a single monolithic table containing all of these columns.

Create migration files to separate the table structure into more logical (ie normalised) tables and use flyway to test that the migrations work properly.

## Assessment

For the afternoon task you will be following a similar route, begin by creating the monolithic table described and then add the files to modify the tables until you end up with a nicely normalised database structure. 

Full details can be found in the repository (remember to Fork and Clone it).

[Afternoon Activity](https://github.com/boolean-uk/java-api-migrations)
