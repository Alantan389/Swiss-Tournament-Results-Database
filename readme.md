# Swiss Tournament Results Database

This is a project for the Udacity course ["Intro to Relational Databases"](https://www.udacity.com/course/ud197).

This project creates a PostgreSQL database to hold the results of a swiss style tournament. It includes code to clear, update and access the database in Python.

## How To Use

Create the database in PostgreSQL via PSQL using the command "create database". Use the name "tournament" for your database.

After connecting with you new database in PSQL, create the tables and views from the statements in "tournament.sql".
	
	You can do this in either of two ways:

	a) Paste each statement in to psql.

	b) Use the command \i tournament.sql to import the whole file into psql at once.

Import tournament.py into your project to utilise database access functions. Please see Python Docstrings for details.

The module tournament_test.py is a series of tests which create, access, and delete data in the database.
