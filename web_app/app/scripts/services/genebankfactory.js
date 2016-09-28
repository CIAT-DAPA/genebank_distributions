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

    /* Get JSON to draw the Sankey Diagram */
    dataFactory.getSankeyCoords = function () {
      var items = $http.get(config.genebanks_sankey).then(function (response) {
        return response.data;
      });
      return items;
    }


    /* Get data to draw the circles in the map */
    dataFactory.getRegionDensity = function (layer) {
      $http.get(config.genebanks_geojson).success(function (data) {
        layer.addGeoJson(data.RegionsDensity);
        layer.setStyle(styleFeature);
      });
    }

    /* Get data to draw the lines in the map */
    dataFactory.getRegionCoords = function (layer) {
      $http.get(config.genebanks_geojson).success(function (data) {
        layer.addGeoJson(data.RegionsCoords);
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

    return dataFactory;
  });
