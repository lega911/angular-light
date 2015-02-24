var gulp = require('gulp');
var coffee = require('gulp-coffee');
var uglify = require('gulp-uglify');
var concat = require('gulp-concat');
var rename = require('gulp-rename');
var header = require('gulp-header');
var clean = require('gulp-clean');


gulp.task('default', ['compress'], function() {
});

gulp.task('clean', function () {
  return gulp.src(['bin', 'tmp'], {read: false})
    .pipe(clean());
});

gulp.task('compile', ['clean'], function() {
  return gulp.src('./alight/*.coffee')
    //.pipe(coffee({bare: true}).on('error', console.log))
    .pipe(coffee({}).on('error', console.log))
    .pipe(gulp.dest('tmp'))
});

gulp.task('assemble', ['compile'], function() {
  var files = [
    './js/prefix.js',
    './js/fquery.js',
    './tmp/core.js',
    './tmp/utilits.js',
    './tmp/parser.js',
    './tmp/compile.js',
    './tmp/directives.js',
    './tmp/drepeat.js',
    './tmp/filters.js',
    './tmp/observer.js',
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
