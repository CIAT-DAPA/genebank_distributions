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
    $(".angular-google-map-container").css('height', ($(document).height()/4) + 'px' );

    $scope.map = {
      center: { latitude: 0, longitude: 0 },
      zoom:3,
      showData: true,
      dataLayerCallback: function(layer) {
        //set the data layer's backend data
        GenebankFactory.getRegionDensity(layer);
        GenebankFactory.getRegionCoords(layer);
      }
    };
  });
