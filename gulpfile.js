var gulp = require('gulp');
var coffee = require('gulp-coffee');
var uglify = require('gulp-uglify');
var concat = require('gulp-concat');
var rename = require('gulp-rename');
var header = require('gulp-header');
var clean = require('gulp-clean');
var replace = require('gulp-replace');
var version = require('./src/js/version.js');

gulp.task('default', ['compress'], function(){});

gulp.task('clean', function () {
  return gulp.src(['tmp'], {read: false})
    .pipe(clean());
});

gulp.task('compile', ['compile_core', 'compile_parser', 'compile_filter', 'compile_directive'], function() {});

gulp.task('compile_core', ['clean'], function() {
  return gulp.src('./src/*.coffee')
    .pipe(coffee({bare: true}).on('error', console.log))
    .pipe(gulp.dest('tmp'))
});

gulp.task('compile_parser', ['clean'], function() {
  return gulp.src('./src/parser/*.coffee')
    .pipe(coffee({bare: true}).on('error', console.log))
    .pipe(gulp.dest('tmp/parser'))
});

gulp.task('compile_filter', ['clean'], function() {
  return gulp.src('./src/filter/*.coffee')
    .pipe(coffee({bare: true}).on('error', console.log))
    .pipe(gulp.dest('tmp/filter'))
});

gulp.task('compile_directive', ['clean'], function() {
  return gulp.src('./src/directive/*.coffee')
    .pipe(coffee({bare: true}).on('error', console.log))
    .pipe(gulp.dest('tmp/directive'))
});

gulp.task('assemble', ['compile'], function() {
  var files = [
    './src/js/prefix.js',
    './src/js/fquery.js',
    './tmp/changeDetector.js',
    './tmp/scope.js',
    './tmp/watchText.js',
    './tmp/textDirective.js',
    './tmp/binding.js',
    './tmp/utils.js',
    './tmp/parser/parseExpression.js',
    './tmp/parser/parseText.js',
    './tmp/compile.js',
    './tmp/fastBinding.js',

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
    './tmp/directive/radio.js',
    './tmp/directive/showHide.js',
    './tmp/directive/style.js',    
    './tmp/directive/select.js',

    './tmp/filter/slice.js',
    './tmp/filter/date.js',
    './tmp/filter/json.js',
    './tmp/filter/filter.js',
    './tmp/filter/generator.js',
    './tmp/filter/orderby.js',
    './tmp/filter/throttle.js',
    './tmp/filter/toarray.js',

    './src/js/postfix.js'
  ];
  return gulp.src(files)
    .pipe(concat('alight.js'))
    .pipe(replace('{{{version}}}', version.version))
    .pipe(header("/**\n * Angular Light " + version.version + "\n * (c) 2015 Oleg Nechaev\n * Released under the MIT License.\n * " + version.date + ", http://angularlight.org/ \n */"))
    .pipe(gulp.dest('bin'));
});

gulp.task('assembleCore', ['compile'], function() {
  var files = [
    './src/js/prefix.js',
    './src/js/fquery.js',
    './tmp/changeDetector.js',
    './tmp/scope.js',
    './tmp/watchText.js',
    './tmp/textDirective.js',
    './tmp/binding.js',
    './tmp/utils.js',
    './tmp/parser/parseExpression.js',
    './tmp/parser/parseText.js',
    './tmp/compile.js',
    './tmp/fastBinding.js',

    './tmp/directive/click.js',
    './tmp/directive/value.js',
    './tmp/directive/checked.js',
    './tmp/directive/if.js',
    './tmp/directive/repeat.js',
    './tmp/directive/init.js',
    './tmp/directive/class.js',
    './tmp/directive/src.js',
    './tmp/directive/app.js',
    './tmp/directive/include.js',
    './tmp/directive/cloak.js',

    './tmp/directive/enable.js',
    './tmp/directive/focused.js',
    './tmp/directive/readonly.js',
    './tmp/directive/submit.js',
    './tmp/directive/event.js',
    './tmp/directive/html.js',

    './tmp/directive/radio.js',
    './tmp/directive/showHide.js',

    './tmp/filter/date.js',
    './tmp/filter/json.js',
    './tmp/filter/generator.js',

    './src/js/postfix.js'
  ];
  return gulp.src(files)
    .pipe(concat('core.js'))
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

gulp.task('core', ['assembleCore'], function() {
  return gulp.src('./bin/core.js')
    .pipe(uglify())
    .pipe(rename({
       extname: '.min.js'
     }))
    .pipe(header("/**\n * Angular Light " + version.version + "\n * (c) 2015 Oleg Nechaev\n * Released under the MIT License.\n * " + version.date + ", http://angularlight.org/ \n */"))
    .pipe(gulp.dest('bin'))
});


// test

gulp.task('build_test', function() {
  return gulp.src('./test/*.coffee')
    //.pipe(coffee({bare: true}).on('error', console.log))
    .pipe(coffee({}).on('error', console.log))
    .pipe(gulp.dest('test'))
});

gulp.task('build_test_core', function() {
  return gulp.src('./test/core/*.coffee')
    //.pipe(coffee({bare: true}).on('error', console.log))
    .pipe(coffee({}).on('error', console.log))
    .pipe(gulp.dest('test/core'))
});

gulp.task('build_test_directive', function() {
  return gulp.src('./test/directive/*.coffee')
    .pipe(coffee({}).on('error', console.log))
    .pipe(gulp.dest('test/directive'))
});

gulp.task('build_test_filter', function() {
  return gulp.src('./test/filter/*.coffee')
    .pipe(coffee({}).on('error', console.log))
    .pipe(gulp.dest('test/filter'))
});

gulp.task('build_test_utils', function() {
  return gulp.src('./test/utils/*.coffee')
    .pipe(coffee({}).on('error', console.log))
    .pipe(gulp.dest('test/utils'))
});

gulp.task('test', ['build_test', 'build_test_core', 'build_test_other', 'build_test_utils', 'build_test_directive', 'build_test_filter'], function(){
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
