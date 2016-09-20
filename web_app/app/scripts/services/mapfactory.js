'use strict';

/**
 * @ngdoc service
 * @name genebanksDistributionApp.MapFactory
 * @description
 * # MapFactory
 * Factory in the genebanksDistributionApp.
 */
angular.module('genebanksDistributionApp')
  .factory('MapFactory', function ($http, config) {

    var dataFactory = {};

    dataFactory.getRegionDensity = function (layer) {
      $http.get(config.genebanks_map).success(function (data) {
        layer.addGeoJson(data.RegionsDensity);
        layer.setStyle(styleFeature);
      });
    }

    function styleFeature(feature) {
      return {
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          strokeWeight: 0.5,
          strokeColor: '#fff',
          fillColor: "#ff00ff",
          fillOpacity: 2 / feature.getProperty('radio'),
          // while an exponent would technically be correct, quadratic looks nicer
          scale: Math.pow(feature.getProperty('radio'), 2)
        },
        zIndex: Math.floor(feature.getProperty('radio'))
      };
    }

    dataFactory.getRegionCoords = function (layer) {
      $http.get(config.genebanks_map).success(function (data) {
        layer.addGeoJson(data.RegionsCoords);
      });
    }


    return dataFactory;
  });
