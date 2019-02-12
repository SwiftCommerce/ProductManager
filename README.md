# Product Manager

The Product Manager is a micro-service that works as the catalog for an e-commerce app. It is built with the server-side Swift framework Vapor.

## Setup

After you have forked and cloned the service, you will need to do a little setup so it can run:

1. MySQL

	Product Manager stores its data in a MySQL database. First, you need to install it:
	
	**Homebrew:**
	
	```bash
	brew install mysql
	mysql_secure_installation
	```
	
	**APT:**
	
	```bash
	sudo apt-get update
	sudo apt-get install mysql-server
	mysql_secure_installation
	```
	
	By default, the service expects the MySQL user to be `root` and the password to be `password`, but you can either change the value in the configuration of set the `DATABASE_USER` and `DATABASE_PASSWORD` environment variables.
	
	You then need to create a database called `product_manager`, or, as before, you can name it something else and change the config or set `DATABASE_DB`
	
2. JWT Tokens

	 Product Manager uses JWT bearer authentication for protecting routes that mutate a collection (`POST`, `PATCH`, and `DELETE` routes). Product Manager relies on another service to create the token when the user authenticates, but it still needs to verify the token. To do this, it needs access to the token's public key. You can give access by assigning it to the `JWT_PUBLIC` key.
	 
## Documentation
	 
You can read the API documentation [here](https://documenter.getpostman.com/view/1912959/RzZCEd6A).
	 
## Vapor Cloud

The MySQL configuration is setup to work seamlessly with Vapor Cloud. Just make sure your replica has a MySQL database for it.

To set the JWT public key, you can run `vapor cloud config modify JWT_PUBLIC=<TOKEN>` from your project root. 
