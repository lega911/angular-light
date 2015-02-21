mkdir -p ./bin
mkdir -p ./tmp

coffee -o ./tmp/ -c ./alight/drepeat.coffee
coffee -o ./tmp/ -c ./alight/animate.coffee
coffee -o ./tmp/ -c ./alight/filters.coffee
coffee -o ./tmp/ -c ./alight/parser.coffee
coffee -o ./tmp/ -c ./alight/compile.coffee
coffee -o ./tmp/ -c ./alight/directives.coffee
coffee -o ./tmp/ -c ./alight/compile.coffee
coffee -o ./tmp/ -c ./alight/core.coffee
coffee -o ./tmp/ -c ./alight/observer.coffee
coffee -o ./tmp/ -c ./alight/utilits.coffee

coffee -c ./test/test_drepeat.coffee
coffee -c ./test/test_main.coffee
coffee -c ./test/test_dirs.coffee
coffee -c ./test/test_scan.coffee
coffee -c ./test/test_pars.coffee
coffee -c ./test/test_utilits.coffee
coffee -c ./test/test_core.coffee
coffee -c ./test/test_observer.coffee
coffee -c ./test/test_ns.coffee
coffee -c ./test/test_compile.coffee
coffee -c ./test/test_filters.coffee

# assemble
cat ./alight/prefix.js > ./bin/alight.js
cat ./alight/fquery.js >> ./bin/alight.js
cat ./tmp/core.js >> ./bin/alight.js
cat ./tmp/utilits.js >> ./bin/alight.js
cat ./tmp/parser.js >> ./bin/alight.js
cat ./tmp/compile.js >> ./bin/alight.js
cat ./tmp/directives.js >> ./bin/alight.js
cat ./tmp/drepeat.js >> ./bin/alight.js
cat ./tmp/filters.js >> ./bin/alight.js
cat ./tmp/observer.js >> ./bin/alight.js
cat ./alight/postfix.js >> ./bin/alight.js

cp ./tmp/animate.js ./bin/animate.js


echo "/**\n * Angular Light\n * (c) 2015 Oleg Nechaev\n * Released under the MIT License.\n */" > ./bin/alight.min.js
minify ./bin/alight.js >> ./bin/alight.min.js
minify ./bin/animate.js > ./bin/animate.min.js
