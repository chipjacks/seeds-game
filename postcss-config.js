module.exports = {
  input: 'src/css/main.css',
  output: 'public/style.min.css',
  use: [
    'autoprefixer',
    'postcss-import',
    'postcss-custom-media',
    'postcss-clean',
    'postcss-custom-properties'
  ]
}
