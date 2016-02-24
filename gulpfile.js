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
var source = require('./source.json');

var resultTag = [];
var resultFile = '';
var resultList = [];

gulp.task('config_core', [], function(){
    resultFile = 'alight_core.js';
    resultTag = ['core'];
});

gulp.task('config_basis', [], function(){
    resultFile = 'alight_basis.js';
    resultTag = ['core', 'basis'];
});

gulp.task('config_full', [], function(){
    resultFile = 'alight_full.js';
    resultTag = ['core', 'basis', 'full'];
});

gulp.task('config_compatibility', [], function(){
    resultFile = 'alight.js';
    resultTag = ['core', 'basis', 'full', 'compatibility'];
});

gulp.task('full', ['config_full', 'prepare', 'compress'], function(){});
gulp.task('basis', ['config_basis', 'prepare', 'compress'], function(){});
gulp.task('default', ['config_compatibility', 'prepare', 'compress'], function(){});
gulp.task('core', ['config_core', 'prepare', 'compress'], function(){});

gulp.task('prepare', [], function(){
    var tags = {};
    for(var i=0; i<resultTag.length; i++)
        tags[resultTag[i]] = true;

    for(var i=0; i<source.length; i++) {
        var f = source[i];
        var skip = true;
        for(var j=0; j<f.tag.length; j++) {
            if(tags[f.tag[j]]) {
                skip = false;
                break;
            }
        }
        if(skip) continue;
        var d = f.file.match(/^(.*\.)(\w+)$/)
        var name = d[1] + 'js';
        var ext = d[2];
        if(ext === 'js') name = './src/' + name
        else name = './tmp/' + name
        resultList.push(name);
    }
});

gulp.task('clean', function () {
  return del.sync(['tmp']);
});

gulp.task('compile', ['compile_coffeescript', 'compile_typescript'], function() {});

gulp.task('compile_coffeescript', ['clean'], function() {
  return gulp.src('./src/**/*.coffee')
    .pipe(coffee({bare: true}).on('error', console.log))
    .pipe(gulp.dest('tmp'))
});


gulp.task('compile_typescript', function() {
    return gulp.src('./src/**/*.es.js')
        .pipe(typescript({
            allowJs: true
        }))
        .pipe(gulp.dest('tmp'))
});


gulp.task('assemble', ['compile'], function() {
  return gulp.src(resultList)
    .pipe(concat(resultFile))
    .pipe(replace('{{{version}}}', version.version))
    .pipe(header("/**\n * Angular Light " + version.version + "\n * (c) 2016 Oleg Nechaev\n * Released under the MIT License.\n * " + version.date + ", http://angularlight.org/ \n */"))
    .pipe(gulp.dest('bin'));
});

gulp.task('compress', ['assemble'], function() {
  return gulp.src('./bin/' + resultFile)
    .pipe(uglify())
    .pipe(rename({
       extname: '.min.js'
     }))
    .pipe(header("/**\n * Angular Light " + version.version + "\n * (c) 2016 Oleg Nechaev\n * Released under the MIT License.\n * " + version.date + ", http://angularlight.org/ \n */"))
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
