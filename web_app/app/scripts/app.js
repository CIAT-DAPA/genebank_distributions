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
      .otherwise({
        redirectTo: '/'
      });
  });
