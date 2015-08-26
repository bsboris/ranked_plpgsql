# Ranking products using PL/pgSQL

To run tests:

    createdb rank_test
    echo 'CREATE EXTENSION hstore;' | psql rank_test
    bundle
    rake

# Development

    bundle exec guard
