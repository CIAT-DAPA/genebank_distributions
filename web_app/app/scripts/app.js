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
      genebanks_sankey: 'data/genebanks.json',
      sankey_depth:1,
      genebanks_geojson: 'data/map_genebanks.json'
  });
