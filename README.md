# Sherpa Documentation

Docs for Sherpa

## Build Container

```
docker build -t sherpa-docs .
```

## Run Container

```
docker run --name sherpa-docs --rm -it -p 8000:8000 -v ${PWD}:/docs sherpa-docs
```

## Build Site

```
docker run --name sherpa-docs --rm -it -v ${PWD}:/docs sherpa-docs build
```
