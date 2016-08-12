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
  .module('genebanksDistributionApp', [
    'ngAnimate',
    'ngCookies',
    'ngRoute'
  ])
  .value('config',{
      data_genebanks: 'data/genebanks.json'
  })
  .config(function ($routeProvider) {
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
      .otherwise({
        redirectTo: '/'
      });
  });
