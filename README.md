# Ranking products using PL/pgSQL

[![Build Status](https://travis-ci.org/bsboris/ranked_plpgsql.svg?branch=master)](https://travis-ci.org/bsboris/ranked_plpgsql)

To run tests:

    createdb rank_test
    echo 'CREATE EXTENSION hstore;' | psql rank_test
    bundle
    rake

# Development

    bundle exec guard
