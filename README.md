# Rust in a container

[![Build Status](https://travis-ci.org/TomasTomecek/rust-container.svg?branch=master)](https://travis-ci.org/TomasTomecek/rust-container)

Latest [Rust](https://github.com/rust-lang/rust/) compiler and
[cargo](https://github.com/rust-lang/cargo/) in a linux container (using
docker).

## Getting the images

The images are available in [my Docker Hub repository](https://hub.docker.com/r/tomastomecek/rust/):

* `$ docker pull tomastomecek/rust` — this is the most recent stable release
* `$ docker pull tomastomecek/rust:nightly` — this is the most recent, functional nightly release
* `$ docker pull tomastomecek/rust:clippy` — latest nightly image with [clippy](https://github.com/Manishearth/rust-clippy)

Every stable image is also tagged with version of Rust compiler, so for example:

```
$ docker pull tomastomecek/rust:1.17.0
```

For more info what versions are available, see the section [Tags](https://hub.docker.com/r/tomastomecek/rust/tags/).


## Usage

You should mount your project inside directory `/src` within the container. `cargo` and `rustc` commands are then available in the container.

Here is a guide how to perform some common actions:

1. Compile a file:
  ```bash
  $ ls -lha .
  total 4.0K
  -rw-rw-r-- 1 me me 37 May 23 13:10 main.rs

  $ docker run -ti -v $PWD:/src/ tomastomecek/rust rustc ./main.rs

  $ ./main
  It works!

  $ ls -lha .
  total 3.5M
  -rwxr-xr-x 1 me me 3.5M May 26 18:11 main
  -rw-rw-r-- 1 me me   37 May 23 13:10 main.rs
  ```

2. Create a new project using cargo:
  ```bash
  $ mkdir the-best-project

  $ cd the-best-project

  $ docker run -ti -v $PWD:/src/ tomastomecek/rust cargo init --bin
       Created binary (application) project

  $ ls -lha .
  total 8.0K
  drwxrwxr-x 4 me me  61 May 26 18:35 .
  drwxrwxr-x 7 me me 143 May 26 18:29 ..
  -rw-r--r-- 1 me me  76 May 26 18:35 Cargo.toml
  drwxr-xr-x 6 me me  96 May 26 18:17 .git
  -rw-r--r-- 1 me me 120 May 26 18:35 .gitignore
  drwxr-xr-x 2 me me  19 May 26 18:35 src
  ```

3. Compile a cargo project:
  ```bash
  $ ls -lh .
  total 8.0K
  -rw-r--r-- 1 me me  76 May 26 18:35 Cargo.toml
  drwxr-xr-x 2 me me  19 May 26 18:35 src

  $ docker run -ti -v $PWD:/src/ tomastomecek/rust cargo build
     Compiling src v0.1.0 (file:///src)
      Finished dev [unoptimized + debuginfo] target(s) in 0.34 secs

  $ ./target/debug/src
  Hello, world!
  ```

## CI/CD pipeline

These images are being created using a very simple CI/CD pipeline. Here's how it works:

1. Travis CI initiates a build every day using its [Cron Jobs](https://github.com/travis-ci/beta-features/issues/1) feature.

2. [This build script](https://github.com/TomasTomecek/rust-container/blob/master/hack/ci.sh) is executed.

3. Rust stable docker image is built.

4. Tests for Rust stable docker image are executed. These tests verify that
   * Rust compiler is able to compile Rust code.
   * Cargo is able to create a new project.
   * This cargo project can be built.

5. If the tests passed, push the image to Docker Hub.

6. Do steps 3 and 4 for nightly image.


With this very simple pipeline you can be sure that

 * you get functional images
 * you get latest Rust compiler
 * you can pick a version of Rust
