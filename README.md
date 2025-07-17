# Ovelha

Mais uma versão da Rinha, desta vez usando Ruby.

<img width="394" height="382" alt="Screenshot 2025-07-17 at 02 07 56" src="https://github.com/user-attachments/assets/c968d1fd-0490-4ba1-819b-651f8d03b9b3" />

## Requisitos

* [Docker](https://docs.docker.com/get-docker/)
* Make (optional)

## Usage

```bash
$ make help

Usage: make <target>
  help                       Prints available commands
  payment-processor.up       Start the payment processor service
  payment-processor.down     Stop the payment processor service
  payment-processor.logs     View logs for the payment processor service
  api.setup                  Set up the API service
  start.dev                  Start the development environment
  docker.stats               Show docker stats
  docker.build               Build the docker image
  docker.push                Push the docker image
  stress.it                  Unleash the madness
  ovelha                     A little test
```

## Inicializando a aplicação

```bash
$ docker compose up -d nginx

# Ou então utilizando Make...
$ make start.dev
```

Health check da app:

```
$ make summary # LOL
```

## Unleash the madness

Colocando K6 no barulho:

```bash
$ make stress.it 
```
