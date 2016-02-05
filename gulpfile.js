var gulp = require('gulp');
var coffee = require('gulp-coffee');
var uglify = require('gulp-uglify');
var concat = require('gulp-concat');
var rename = require('gulp-rename');
var header = require('gulp-header');
var replace = require('gulp-replace');
var version = require('./src/js/version.js');
var typescript = require('gulp-typescript');
var del = require('del');

gulp.task('default', ['compress'], function(){});

gulp.task('clean', function () {
  return del.sync(['tmp']);
});

gulp.task('compile', ['compile_coffeescript', 'compile_typescript'], function() {});

gulp.task('compile_coffeescript', ['clean'], function() {
  return gulp.src('./src/**/*.coffee')
    .pipe(coffee({bare: true}).on('error', console.log))
    .pipe(gulp.dest('tmp'))
});

gulp.task('compile_typescript', function () {
    return gulp.src('./src/**/*.ts')
        .pipe(typescript({
            noImplicitAny: true
        }))
        .pipe(gulp.dest('tmp'))
});

var allFiles = [
  './src/js/prefix.js',
  './src/js/fquery.js',
  './tmp/changeDetector.js',
  './tmp/scope.js',
  './tmp/watchText.js',
  './tmp/binding.js',
  './tmp/utils.js',
  './tmp/parser/parseExpression.js',
  './tmp/parser/parseText.js',
  './tmp/compile.js',
  './tmp/fastBinding.js',
  './tmp/event.js',

  './tmp/directive/click.js',
  './tmp/directive/value.js',
  './tmp/directive/checked.js',
  './tmp/directive/if.js',
  './tmp/directive/repeat.js',
  './tmp/directive/init.js',
  './tmp/directive/class.js',
  './tmp/directive/src.js',
  './tmp/directive/text.js',
  './tmp/directive/app.js',
  './tmp/directive/bindonce.js',
  './tmp/directive/stop.js',
  './tmp/directive/include.js',

  './tmp/directive/cloak.js',
  './tmp/directive/enable.js',
  './tmp/directive/focused.js',
  './tmp/directive/readonly.js',
  './tmp/directive/submit.js',
  './tmp/directive/event.js',
  './tmp/directive/html.js',
  './tmp/directive/htmlbyid.js',
  './tmp/directive/radio.js',
  './tmp/directive/showHide.js',
  './tmp/directive/style.js',
  './tmp/directive/select.js',
  './tmp/directive/ctrl.js',
  './tmp/directive/attr.js',

  './tmp/filter/slice.js',
  './tmp/filter/date.js',
  './tmp/filter/json.js',
  './tmp/filter/filter.js',
  './tmp/filter/generator.js',
  './tmp/filter/orderby.js',
  './tmp/filter/throttle.js',
  './tmp/filter/toarray.js',
  './tmp/filter/storeto.js',

  './tmp/text/bindOnce.js',
  './tmp/text/oneTimeBinding.js',
  './tmp/text/textWatch.js',

  './src/js/postfix.js'
];

gulp.task('assemble', ['compile'], function() {
  return gulp.src(allFiles)
    .pipe(concat('alight.js'))
    .pipe(replace('{{{version}}}', version.version))
    .pipe(header("/**\n * Angular Light " + version.version + "\n * (c) 2015 Oleg Nechaev\n * Released under the MIT License.\n * " + version.date + ", http://angularlight.org/ \n */"))
    .pipe(gulp.dest('bin'));
});

gulp.task('assembleIE8', ['compile'], function() {
    allFiles.splice(2, 0, './src/js/fqueryIE8.js');
    return gulp.src(allFiles)
        .pipe(concat('alightie.js'))
        .pipe(replace('{{{version}}}', version.version))
        .pipe(header("/**\n * Angular Light " + version.version + "\n * (c) 2015 Oleg Nechaev\n * Released under the MIT License.\n * " + version.date + ", http://angularlight.org/ \n */"))
        .pipe(gulp.dest('bin'));
});

gulp.task('compress', ['assemble'], function() {
  return gulp.src('./bin/alight.js')
    .pipe(uglify())
    .pipe(rename({
       extname: '.min.js'
     }))
    .pipe(header("/**\n * Angular Light " + version.version + "\n * (c) 2015 Oleg Nechaev\n * Released under the MIT License.\n * " + version.date + ", http://angularlight.org/ \n */"))
    .pipe(gulp.dest('bin'))
});

gulp.task('ie', ['assembleIE8'], function() {
  return gulp.src('./bin/alightie.js')
    .pipe(uglify())
    .pipe(rename({
       extname: '.min.js'
     }))
    .pipe(header("/**\n * Angular Light " + version.version + "\n * (c) 2015 Oleg Nechaev\n * Released under the MIT License.\n * " + version.date + ", http://angularlight.org/ \n */"))
    .pipe(gulp.dest('bin'))
});


// test

gulp.task('build_test', function() {
  return gulp.src('./test/**/*.coffee')
    //.pipe(coffee({bare: true}).on('error', console.log))
    .pipe(coffee({}).on('error', console.log))
    .pipe(gulp.dest('test'))
});

gulp.task('test', ['build_test'], function(){
  var path = require('path');
  var childProcess = require('child_process');
  var phantomjs = require('phantomjs');
  var binPath = phantomjs.path;
  var childArgs = [path.join('test', 'phantom.js')];

  childProcess.execFile(binPath, childArgs, function(err, stdout, stderr) {
    console.log(stdout);
  });
});

gulp.task('build_test_other', function() {
  gulp.src('./test/benchmark/*.coffee')
    .pipe(coffee({}).on('error', console.log))
    .pipe(gulp.dest('test/benchmark'))
});
