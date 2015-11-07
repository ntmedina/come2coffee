== README

# Starting the project with docker
## To start docker machine
1. `docker-machine create -d virtualbox dev`
2. `docker-machine start dev~
3. `eval $(docker-machine env dev)`

## To build the image and create the databases and tables
1. `docker-compose build`
2. `docker-compose run --rm web db:create`
3. `docker-compose run --rm web db:migrate`

## To run the project and open in browser <3
1. `docker-compose up`
2. `open "http://$(docker-machine ip dev):3000"`

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


Please feel free to use a different markup language if you do not plan to run
<tt>rake doc:app</tt>.
