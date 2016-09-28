'use strict';

/**
 * @ngdoc function
 * @name genebanksDistributionApp.controller:MapCtrl
 * @description
 * # MapCtrl
 * Controller of the genebanksDistributionApp
 */
angular.module('genebanksDistributionApp')
  .controller('MapCtrl', function ($scope, GenebankFactory) {
    $scope.map = {
      center: { latitude: 0, longitude: 0 },
      zoom: 2,
      showData: true,
      dataLayerCallback: function(layer) {
        //set the data layer's backend data
        //GenebankFactory.getRegionDensity(layer);
        //GenebankFactory.getRegionCoords(layer);
      }
    };
  });
