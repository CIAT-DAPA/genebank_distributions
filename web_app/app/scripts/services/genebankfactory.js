'use strict';

/**
 * @ngdoc service
 * @name genebanksDistributionApp.GenebankFactory
 * @description
 * # GenebankFactory
 * Factory in the genebanksDistributionApp.
 */
angular.module('genebanksDistributionApp')
  .factory('GenebankFactory', function ($http, config) {
    var dataFactory = {};
    dataFactory.list = function () {
      var items = $http.get(config.data_genebanks).then(function (response) {
        return response.data;
      });
      return items;
    }
    return dataFactory;
  });
