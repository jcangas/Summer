
var gulp  = require('gulp')
var shell = require('gulp-shell')
var paths = {
 site: ['.', '!_site/**']
}
gulp.task('build', shell.task('bundle exec jekyll build'))
gulp.task('serve', shell.task("bundle exec jekyll serve  --baseurl '' --watch"))
gulp.task('watch', function () {
  gulp.watch(paths.site, ['build'])
})