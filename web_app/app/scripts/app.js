'use strict';

/**
 * @ngdoc overview
 * @name genebanksDistributionApp
 * @description
 * # genebanksDistributionApp
 *
 * Main module of the application.
 */
angular
  .module('genebanksDistributionApp',  ['swipe','snapscroll','uiGmapgoogle-maps'])
  .value('config',{
      data_genebanks: 'data/genebanks.json',
      sankey_depth:1,
      genebanks_map: 'data/map_genebanks.json'
  });
/*  .config(function ($routeProvider) {
    $routeProvider
      .when('/', {
        templateUrl: 'views/main.html',
        controller: 'MainCtrl',
        controllerAs: 'main'
      })
      .when('/about', {
        templateUrl: 'views/about.html',
        controller: 'AboutCtrl',
        controllerAs: 'about'
      })
      .when('/sankey', {
        templateUrl: 'views/sankey.html',
        controller: 'SankeyCtrl',
        controllerAs: 'csankey'
      })
      .when('/map', {
        templateUrl: 'views/map.html',
        controller: 'MapCtrl',
        controllerAs: 'cmap'
      })
      .otherwise({
        redirectTo: '/'
      });
  });*/
