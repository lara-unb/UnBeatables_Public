const webpack = require('webpack'); const config = {
    entry: __dirname + '/js/init.js',
    output: {
        path: __dirname + '/dist',
        filename: 'bundle.js',
    },
    resolve: {
        extensions: ['.js', '.jsx', '.css']
    },
}; module.exports = config;