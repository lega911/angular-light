var gulp = require('gulp');
var coffee = require('gulp-coffee');
var uglify = require('gulp-uglify');
var concat = require('gulp-concat');
var rename = require('gulp-rename');
var header = require('gulp-header');
var clean = require('gulp-clean');


gulp.task('default', ['compress'], function(){});

gulp.task('clean', function () {
  return gulp.src(['bin', 'tmp'], {read: false})
    .pipe(clean());
});

gulp.task('compile', ['compile_core', 'compile_parser', 'compile_filter', 'compile_directive'], function() {});

gulp.task('compile_core', ['clean'], function() {
  return gulp.src('./alight/*.coffee')
    .pipe(coffee({bare: true}).on('error', console.log))
    .pipe(gulp.dest('tmp'))
});

gulp.task('compile_parser', ['clean'], function() {
  return gulp.src('./alight/parser/*.coffee')
    .pipe(coffee({bare: true}).on('error', console.log))
    .pipe(gulp.dest('tmp/parser'))
});

gulp.task('compile_filter', ['clean'], function() {
  return gulp.src('./alight/filter/*.coffee')
    .pipe(coffee({bare: true}).on('error', console.log))
    .pipe(gulp.dest('tmp/filter'))
});

gulp.task('compile_directive', ['clean'], function() {
  return gulp.src('./alight/directive/*.coffee')
    .pipe(coffee({bare: true}).on('error', console.log))
    .pipe(gulp.dest('tmp/directive'))
});

gulp.task('assemble', ['compile'], function() {
  var files = [
    './js/prefix.js',
    './js/fquery.js',
    './tmp/node.js',
    './tmp/scope.js',
    './tmp/core.js',
    './tmp/watchText.js',
    './tmp/utils.js',
    './tmp/parser/parseExpression.js',
    './tmp/parser/parseText.js',
    './tmp/compile.js',

    './tmp/directive/app.js',
    './tmp/directive/bindonce.js',
    './tmp/directive/checked.js',
    './tmp/directive/class.js',
    './tmp/directive/click.js',
    './tmp/directive/cloak.js',
    './tmp/directive/controller.js',
    './tmp/directive/enable.js',
    './tmp/directive/event.js',
    './tmp/directive/focused.js',
    './tmp/directive/html.js',
    './tmp/directive/if.js',
    './tmp/directive/include.js',
    './tmp/directive/init.js',
    './tmp/directive/radio.js',
    './tmp/directive/readonly.js',
    './tmp/directive/showHide.js',
    './tmp/directive/src.js',
    './tmp/directive/stop.js',
    './tmp/directive/style.js',
    './tmp/directive/submit.js',
    './tmp/directive/text.js',
    './tmp/directive/value.js',
    './tmp/directive/repeat.js',
    './tmp/textDirective.js',

    './tmp/filter/date.js',
    './tmp/filter/filter.js',
    './tmp/filter/generator.js',
    './tmp/filter/json.js',
    './tmp/filter/slice.js',

    './js/postfix.js'
  ];
  return gulp.src(files)
    .pipe(concat('alight.js'))
    .pipe(gulp.dest('bin'));
});

gulp.task('compress', ['assemble'], function() {
  return gulp.src('./bin/alight.js')
    .pipe(uglify())
    .pipe(rename({
       extname: '.min.js'
     }))
    .pipe(header("/**\n * Angular Light\n * (c) 2015 Oleg Nechaev\n * Released under the MIT License.\n */"))
    .pipe(gulp.dest('bin'))
});

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


gulp.task('test', ['build_test', 'build_test_core'], function(){
  var path = require('path');
  var childProcess = require('child_process');
  var phantomjs = require('phantomjs');
  var binPath = phantomjs.path;
  var childArgs = [path.join('test', 'phantom.js')];

  childProcess.execFile(binPath, childArgs, function(err, stdout, stderr) {
    console.log(stdout);
  });
});
